import hashlib
import time
from typing import Any, Dict
from urllib.error import HTTPError, URLError
from urllib.parse import urljoin
from urllib.request import HTTPRedirectHandler, Request, build_opener

from .extract import extract_documentation
from .url_security import UrlRejected, validate_url


class NoRedirect(HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None


class FetchFailed(RuntimeError):
    pass


def _read_limited(response: Any, limit: int) -> bytes:
    data = response.read(limit + 1)
    if len(data) > limit:
        raise FetchFailed("response_too_large")
    return data


def fetch_page(source: Dict[str, Any], url: str, *, timeout: int, max_bytes: int, max_redirects: int, max_chars: int) -> Dict[str, Any]:
    current_url = validate_url(source, url)
    opener = build_opener(NoRedirect)
    for _ in range(max_redirects + 1):
        request = Request(current_url, headers={"User-Agent": "bedrock-rag-live-doc-fetch/1.0", "Accept": "text/html, text/plain"})
        try:
            with opener.open(request, timeout=timeout) as response:
                content_type = response.headers.get("content-type", "").split(";", 1)[0].strip().lower()
                if content_type not in {"text/html", "text/plain", "application/xhtml+xml"}:
                    raise FetchFailed("unsupported_content_type")
                body = _read_limited(response, max_bytes)
                if content_type == "text/plain":
                    text = body.decode("utf-8", errors="replace")[:max_chars]
                    title = current_url.rsplit("/", 2)[-2:]
                    page_title = " ".join(part for part in title if part)[:200]
                else:
                    page_title, text = extract_documentation(body, max_chars)
                if not text.strip():
                    raise FetchFailed("empty_extracted_content")
                return {
                    "url": current_url,
                    "title": page_title or source.get("display_name") or current_url,
                    "text": text,
                    "fetched_at": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
                    "content_hash": hashlib.sha256(text.encode("utf-8")).hexdigest(),
                    "source_id": source.get("source_id"),
                    "product": source.get("product"),
                    "version": source.get("version", "current"),
                    "bytes": len(body),
                }
        except HTTPError as exc:
            if exc.code in {301, 302, 303, 307, 308}:
                location = exc.headers.get("location")
                if not location:
                    raise FetchFailed("redirect_missing_location") from exc
                current_url = validate_url(source, urljoin(current_url, location))
                continue
            raise FetchFailed(f"http_{exc.code}") from exc
        except (URLError, TimeoutError, UrlRejected) as exc:
            raise FetchFailed(type(exc).__name__) from exc
    raise FetchFailed("too_many_redirects")
