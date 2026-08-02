import ipaddress
import posixpath
import socket
from typing import Any, Dict, List
from urllib.parse import quote, unquote, urlsplit, urlunsplit


BLOCKED_HOSTS = {"localhost", "169.254.169.254"}
ALLOWED_PORTS = {443}


class UrlRejected(ValueError):
    pass


def _idna_hostname(hostname: str) -> str:
    try:
        return hostname.encode("idna").decode("ascii").lower()
    except UnicodeError as exc:
        raise UrlRejected("invalid_hostname") from exc


def _normalize_path(path: str) -> str:
    decoded = unquote(path or "/")
    if "\x00" in decoded or "\\" in decoded:
        raise UrlRejected("unsafe_path")
    if decoded.startswith("//"):
        raise UrlRejected("protocol_relative_path")
    normalized = posixpath.normpath(decoded)
    if not normalized.startswith("/"):
        normalized = f"/{normalized}"
    if decoded.endswith("/") and not normalized.endswith("/"):
        normalized = f"{normalized}/"
    return quote(normalized, safe="/-._~")


def _prefix_matches(path: str, prefixes: List[str]) -> bool:
    decoded_path = unquote(path)
    for prefix in prefixes:
        decoded_prefix = unquote(prefix or "/")
        if not decoded_prefix.startswith("/"):
            decoded_prefix = f"/{decoded_prefix}"
        normalized_prefix = posixpath.normpath(decoded_prefix)
        if decoded_prefix.endswith("/") and not normalized_prefix.endswith("/"):
            normalized_prefix = f"{normalized_prefix}/"
        if decoded_path == normalized_prefix.rstrip("/") or decoded_path.startswith(normalized_prefix):
            return True
    return False


def _validate_addresses(hostname: str, port: int) -> None:
    try:
        infos = socket.getaddrinfo(hostname, port, type=socket.SOCK_STREAM)
    except socket.gaierror as exc:
        raise UrlRejected("dns_resolution_failed") from exc
    if not infos:
        raise UrlRejected("dns_no_records")
    for info in infos:
        address = info[4][0]
        ip = ipaddress.ip_address(address)
        if (
            ip.is_loopback
            or ip.is_link_local
            or ip.is_private
            or ip.is_multicast
            or ip.is_reserved
            or ip.is_unspecified
        ):
            raise UrlRejected("blocked_ip_address")


def validate_url(source: Dict[str, Any], url: str, *, validate_dns: bool = True) -> str:
    if url.startswith("//"):
        raise UrlRejected("protocol_relative_url")
    parsed = urlsplit(url)
    if parsed.scheme.lower() != "https":
        raise UrlRejected("https_required")
    if parsed.username or parsed.password:
        raise UrlRejected("userinfo_not_allowed")
    if not parsed.hostname:
        raise UrlRejected("hostname_required")
    hostname = _idna_hostname(parsed.hostname)
    if hostname in BLOCKED_HOSTS:
        raise UrlRejected("blocked_hostname")
    allowed_hosts = {_idna_hostname(str(host)) for host in source.get("hostnames", [])}
    if hostname not in allowed_hosts:
        raise UrlRejected("hostname_not_allowed")
    port = parsed.port or 443
    allowed_ports = set(source.get("allowed_ports") or ALLOWED_PORTS)
    if port not in allowed_ports:
        raise UrlRejected("port_not_allowed")
    path = _normalize_path(parsed.path)
    prefixes = [str(prefix) for prefix in source.get("path_prefixes", ["/"])]
    if not _prefix_matches(path, prefixes):
        raise UrlRejected("path_not_allowed")
    if validate_dns:
        _validate_addresses(hostname, port)
    netloc = hostname if port == 443 else f"{hostname}:{port}"
    return urlunsplit(("https", netloc, path, parsed.query, ""))
