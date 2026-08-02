import unittest
from unittest.mock import Mock, patch

from src.query_lambda.live_docs.citations import filter_cited_sources
from src.query_lambda.live_docs.extract import extract_documentation
from src.query_lambda.live_docs.orchestrator import should_try_live_fetch
from src.query_lambda.live_docs.search import search_catalogue
from src.query_lambda.live_docs.url_security import UrlRejected, validate_url


SOURCE = {
    "source_id": "terraform",
    "display_name": "Terraform",
    "product": "terraform",
    "enabled": True,
    "hostnames": ["developer.hashicorp.com"],
    "path_prefixes": ["/terraform/"],
    "catalogue": [{
        "title": "S3 backend",
        "url": "https://developer.hashicorp.com/terraform/language/backend/s3",
        "keywords": ["terraform", "s3", "backend", "state"],
    }],
}


class LiveDocsTests(unittest.TestCase):
    def test_live_fetch_disabled(self):
        should_fetch, reason = should_try_live_fetch("latest terraform", [], enabled=False, min_score=0.65)
        self.assertFalse(should_fetch)
        self.assertIsNone(reason)

    def test_live_fetch_when_no_kb_results(self):
        should_fetch, reason = should_try_live_fetch("terraform backend", [], enabled=True, min_score=0.65)
        self.assertTrue(should_fetch)
        self.assertEqual(reason, "no_kb_results")

    def test_live_fetch_when_freshness_requested(self):
        should_fetch, reason = should_try_live_fetch("latest terraform backend", [{"score": 0.9, "content": {"text": "x"}}], enabled=True, min_score=0.65)
        self.assertTrue(should_fetch)
        self.assertEqual(reason, "freshness_requested")

    @patch("socket.getaddrinfo")
    def test_approved_url(self, getaddrinfo):
        getaddrinfo.return_value = [(None, None, None, None, ("8.8.8.8", 443))]
        url = validate_url(SOURCE, "https://developer.hashicorp.com/terraform/language/backend/s3#state")
        self.assertEqual(url, "https://developer.hashicorp.com/terraform/language/backend/s3")

    def test_rejects_similar_hostname(self):
        with self.assertRaises(UrlRejected):
            validate_url(SOURCE, "https://developer.hashicorp.com.attacker.example/terraform/")

    def test_rejects_path_boundary_confusion(self):
        with self.assertRaises(UrlRejected):
            validate_url(SOURCE, "https://developer.hashicorp.com/terraform-malicious/")

    def test_search_catalogue(self):
        results = search_catalogue("terraform s3 backend state", [SOURCE], 3)
        self.assertEqual(len(results), 1)
        self.assertEqual(results[0]["url"], "https://developer.hashicorp.com/terraform/language/backend/s3")

    def test_extract_removes_script_and_hidden(self):
        html = b"<html><head><title>Doc</title><script>bad()</script></head><body><main><h1>Pods</h1><p>Useful text.</p><div hidden>secret</div></main></body></html>"
        title, text = extract_documentation(html, 500)
        self.assertEqual(title, "Doc")
        self.assertIn("Useful text.", text)
        self.assertNotIn("bad", text)
        self.assertNotIn("secret", text)

    def test_filter_cited_sources_removes_unknown_ids(self):
        answer, sources = filter_cited_sources("Answer [1] [9].", [{"id": 1, "title": "A"}])
        self.assertEqual(answer, "Answer [1] .")
        self.assertEqual(len(sources), 1)


if __name__ == "__main__":
    unittest.main()
