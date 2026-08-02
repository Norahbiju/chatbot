from html.parser import HTMLParser
from typing import Dict


class DocumentationExtractor(HTMLParser):
    BLOCK_TAGS = {"p", "div", "section", "article", "br", "li", "tr", "pre", "code", "h1", "h2", "h3", "h4"}
    SKIP_TAGS = {"script", "style", "form", "nav", "footer", "aside", "noscript", "svg"}

    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self.parts = []
        self.title_parts = []
        self.in_title = False
        self.skip_stack = []

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        attr_map: Dict[str, str] = {key.lower(): value or "" for key, value in attrs}
        hidden = "hidden" in attr_map or "display:none" in attr_map.get("style", "").replace(" ", "").lower()
        if tag in self.SKIP_TAGS or hidden:
            self.skip_stack.append(tag)
        if tag == "title":
            self.in_title = True
        if not self.skip_stack and tag in self.BLOCK_TAGS:
            self.parts.append("\n")

    def handle_endtag(self, tag: str) -> None:
        if tag == "title":
            self.in_title = False
        if not self.skip_stack and tag in self.BLOCK_TAGS:
            self.parts.append("\n")
        if self.skip_stack and tag == self.skip_stack[-1]:
            self.skip_stack.pop()

    def handle_data(self, data: str) -> None:
        text = " ".join(data.split())
        if not text:
            return
        if self.in_title:
            self.title_parts.append(text)
        if not self.skip_stack:
            self.parts.append(text)
            self.parts.append(" ")

    def handle_comment(self, data: str) -> None:
        return


def extract_documentation(html: bytes, max_chars: int) -> tuple[str, str]:
    parser = DocumentationExtractor()
    parser.feed(html.decode("utf-8", errors="replace"))
    text = "\n".join(line.strip() for line in "".join(parser.parts).splitlines() if line.strip())
    title = " ".join(parser.title_parts).strip()
    return title[:200], text[:max_chars]
