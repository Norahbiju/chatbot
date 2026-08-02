import re
from typing import Any, Dict, List

from .url_security import UrlRejected, validate_url


TOKEN_RE = re.compile(r"[a-z0-9][a-z0-9._-]*")
PRODUCT_HINTS = {
    "kubernetes": {"kubernetes", "k8s", "pod", "pods", "service", "deployment", "cluster", "pvc"},
    "github-actions": {"github", "actions", "workflow", "runner", "oidc", "permissions", "yaml"},
    "terraform": {"terraform", "tf", "provider", "state", "backend", "plan", "apply", "module", "variable"},
}


def tokens(text: str) -> set[str]:
    return set(TOKEN_RE.findall(text.lower()))


def likely_products(question: str) -> set[str]:
    question_tokens = tokens(question)
    products = set()
    for product, hints in PRODUCT_HINTS.items():
        if question_tokens & hints:
            products.add(product)
    return products


def search_catalogue(question: str, sources: List[Dict[str, Any]], max_pages: int) -> List[Dict[str, Any]]:
    question_tokens = tokens(question)
    products = likely_products(question)
    candidates = []
    for source in sources:
        product = str(source.get("product", "")).lower()
        if products and product not in products:
            continue
        for item in source.get("catalogue", []):
            if not isinstance(item, dict):
                continue
            try:
                url = validate_url(source, str(item.get("url", "")), validate_dns=False)
            except UrlRejected:
                continue
            haystack = tokens(" ".join([
                str(item.get("title", "")),
                str(item.get("url", "")),
                " ".join(str(keyword) for keyword in item.get("keywords", [])),
            ]))
            score = len(question_tokens & haystack)
            if product in products:
                score += 2
            if score <= 0:
                continue
            candidates.append({"source": source, "item": item, "url": url, "score": score})
    candidates.sort(key=lambda candidate: candidate["score"], reverse=True)
    return candidates[:max_pages]
