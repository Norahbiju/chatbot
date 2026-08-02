import re
from typing import Any, Dict, List


CITATION_RE = re.compile(r"\[(\d+)\]")


def referenced_citation_ids(answer: str) -> set[int]:
    return {int(match) for match in CITATION_RE.findall(answer or "")}


def remove_unknown_citations(answer: str, allowed_ids: set[int]) -> str:
    def replace(match: re.Match[str]) -> str:
        citation_id = int(match.group(1))
        return match.group(0) if citation_id in allowed_ids else ""

    return CITATION_RE.sub(replace, answer or "")


def filter_cited_sources(answer: str, sources: List[Dict[str, Any]]) -> tuple[str, List[Dict[str, Any]]]:
    allowed_ids = {int(source["id"]) for source in sources}
    cleaned = remove_unknown_citations(answer, allowed_ids)
    cited_ids = referenced_citation_ids(cleaned)
    if not cited_ids:
        return cleaned.strip(), sources
    return cleaned.strip(), [source for source in sources if int(source["id"]) in cited_ids]
