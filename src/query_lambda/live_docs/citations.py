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
    cited_ids_in_order = []
    for match in CITATION_RE.findall(cleaned):
        citation_id = int(match)
        if citation_id not in cited_ids_in_order:
            cited_ids_in_order.append(citation_id)
    if not cited_ids_in_order:
        return cleaned.strip(), [_public_source(source, index) for index, source in enumerate(sources, start=1)]

    selected = [source for citation_id in cited_ids_in_order for source in sources if int(source["id"]) == citation_id]
    id_map = {old_id: new_id for new_id, old_id in enumerate(cited_ids_in_order, start=1)}
    renumbered = CITATION_RE.sub(lambda match: f"[{id_map[int(match.group(1))]}]", cleaned)
    return renumbered.strip(), [_public_source(source, index) for index, source in enumerate(selected, start=1)]


def _public_source(source: Dict[str, Any], citation_id: int) -> Dict[str, Any]:
    public = dict(source)
    public["id"] = citation_id
    public.pop("evidence", None)
    return public
