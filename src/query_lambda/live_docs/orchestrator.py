import json
import logging
from typing import Any, Dict, List

from botocore.exceptions import ClientError

from .fetch import FetchFailed, fetch_page
from .registry import enabled_sources, load_registry
from .search import search_catalogue
from .url_security import UrlRejected

LOG = logging.getLogger()

FRESHNESS_WORDS = {"latest", "current", "new", "recent", "today", "official", "docs", "documentation"}


def should_try_live_fetch(message: str, retrieval_results: List[Dict[str, Any]], *, enabled: bool, min_score: float) -> tuple[bool, str | None]:
    if not enabled:
        return False, None
    text = message.lower()
    if any(word in text for word in FRESHNESS_WORDS):
        return True, "freshness_requested"
    if not retrieval_results:
        return True, "no_kb_results"
    best_score = max(float(result.get("score", 0)) for result in retrieval_results)
    if best_score < min_score:
        return True, "low_kb_score"
    if not any((result.get("content") or {}).get("text", "").strip() for result in retrieval_results):
        return True, "empty_kb_text"
    return False, None


def get_live_document_contexts(
    *,
    message: str,
    ssm_client: Any,
    registry_parameter: str,
    max_pages: int,
    timeout: int,
    max_response_bytes: int,
    max_total_bytes: int,
    max_redirects: int,
    max_chars_per_page: int,
) -> List[Dict[str, Any]]:
    try:
        registry = load_registry(ssm_client, registry_parameter)
        candidates = search_catalogue(message, enabled_sources(registry), max_pages)
    except (ClientError, ValueError, json.JSONDecodeError) as exc:
        LOG.warning(json.dumps({"event": "live_doc_registry_error", "error": type(exc).__name__}))
        return []

    contexts = []
    total_bytes = 0
    for candidate in candidates:
        source = candidate["source"]
        per_source_pages = int(source.get("max_pages_per_query", max_pages))
        if len(contexts) >= min(max_pages, per_source_pages):
            break
        try:
            page = fetch_page(
                source,
                candidate["url"],
                timeout=min(timeout, int(source.get("request_timeout", timeout))),
                max_bytes=min(max_response_bytes, int(source.get("max_response_bytes", max_response_bytes))),
                max_redirects=max_redirects,
                max_chars=max_chars_per_page,
            )
            total_bytes += int(page.get("bytes", 0))
            if total_bytes > max_total_bytes:
                LOG.warning(json.dumps({"event": "live_doc_total_bytes_exceeded"}))
                break
            contexts.append(page)
        except (FetchFailed, UrlRejected) as exc:
            LOG.info(json.dumps({"event": "live_doc_fetch_rejected", "url": candidate["url"], "reason": str(exc)}))
    return contexts
