import importlib
import json
import os
import unittest
import uuid
from io import BytesIO
from unittest.mock import Mock, patch

from botocore.exceptions import ClientError


SESSION = str(uuid.uuid4())


class QueryTests(unittest.TestCase):
    def setUp(self):
        os.environ["CONVERSATION_TABLE_NAME"] = "table"
        os.environ["KNOWLEDGE_BASE_ID"] = "kb"
        os.environ["MODEL_ID"] = "apac.amazon.nova-micro-v1:0"
        os.environ.pop("ENABLE_LIVE_DOC_FETCH", None)
        with patch("boto3.resource") as resource, patch("boto3.client") as client:
            self.table = Mock()
            resource.return_value.Table.return_value = self.table
            self.agent = Mock()
            self.runtime = Mock()
            self.ssm = Mock()
            client.side_effect = lambda service, **kwargs: {
                "bedrock-agent-runtime": self.agent,
                "bedrock-runtime": self.runtime,
                "ssm": self.ssm,
            }[service]
            import src.query_lambda.handler as handler
            self.handler = importlib.reload(handler)
            self.handler.dynamodb.Table.return_value = self.table
            self.handler.bedrock_agent_runtime = self.agent
            self.handler.bedrock_runtime = self.runtime
            self.handler.ssm = self.ssm

    def event(self, body):
        return {"version": "2.0", "body": json.dumps(body)}

    def model_response(self, text="Answer [1]."):
        self.runtime.invoke_model.return_value = {"body": BytesIO(json.dumps({"output": {"message": {"content": [{"text": text}]}}}).encode())}

    def retrieval_response(self):
        self.agent.retrieve.return_value = {"retrievalResults": [{"content": {"text": "Terraform state locking prevents concurrent writes."}, "score": 0.82, "location": {"s3Location": {"uri": "s3://b/documents/terraform-basics.md"}}, "metadata": {"title": "Terraform Basics"}}]}

    def test_valid_question(self):
        self.table.query.return_value = {"Items": []}
        self.retrieval_response()
        self.model_response()
        result = self.handler.lambda_handler(self.event({"sessionId": SESSION, "message": "What is locking?"}), None)
        self.assertEqual(result["statusCode"], 200)
        self.assertEqual(self.table.put_item.call_count, 2)
        body = json.loads(result["body"])
        self.assertFalse(body["live_fetch_used"])

    def test_invalid_json(self):
        result = self.handler.lambda_handler({"body": "{"}, None)
        self.assertEqual(result["statusCode"], 400)

    def test_missing_session_id(self):
        result = self.handler.lambda_handler(self.event({"message": "x"}), None)
        self.assertEqual(result["statusCode"], 400)

    def test_invalid_session_id(self):
        result = self.handler.lambda_handler(self.event({"sessionId": "bad", "message": "x"}), None)
        self.assertEqual(result["statusCode"], 400)

    def test_empty_message(self):
        result = self.handler.lambda_handler(self.event({"sessionId": SESSION, "message": " "}), None)
        self.assertEqual(result["statusCode"], 400)

    def test_oversized_message(self):
        result = self.handler.lambda_handler(self.event({"sessionId": SESSION, "message": "x" * 2001}), None)
        self.assertEqual(result["statusCode"], 413)

    def test_session_history_query(self):
        self.table.query.return_value = {"Items": [{"role": "user", "content": "old", "expires_at": 9999999999}]}
        self.retrieval_response()
        self.model_response()
        self.handler.lambda_handler(self.event({"sessionId": SESSION, "message": "x"}), None)
        self.table.query.assert_called_once()

    def test_empty_retrieval(self):
        self.table.query.return_value = {"Items": []}
        self.agent.retrieve.return_value = {"retrievalResults": []}
        result = self.handler.lambda_handler(self.event({"sessionId": SESSION, "message": "x"}), None)
        self.assertEqual(result["statusCode"], 200)
        self.runtime.invoke_model.assert_not_called()

    def test_malformed_generation_response(self):
        self.table.query.return_value = {"Items": []}
        self.retrieval_response()
        self.runtime.invoke_model.return_value = {"body": BytesIO(b"{}")}
        result = self.handler.lambda_handler(self.event({"sessionId": SESSION, "message": "x"}), None)
        self.assertEqual(result["statusCode"], 500)

    def test_citation_construction(self):
        citation = self.handler._citations([{"content": {"text": "abc"}, "score": 1, "location": {"s3Location": {"uri": "s3://b/documents/a.md"}}}])[0]
        self.assertEqual(citation["id"], 1)
        self.assertEqual(citation["source"], "documents/a.md")
        self.assertEqual(citation["source_type"], "KNOWLEDGE_BASE")

    def test_bedrock_throttling(self):
        self.table.query.return_value = {"Items": []}
        self.agent.retrieve.side_effect = ClientError({"Error": {"Code": "ThrottlingException"}}, "Retrieve")
        result = self.handler.lambda_handler(self.event({"sessionId": SESSION, "message": "x"}), None)
        self.assertEqual(result["statusCode"], 429)

    def test_ttl_calculation_and_writes(self):
        self.table.query.return_value = {"Items": []}
        self.agent.retrieve.return_value = {"retrievalResults": []}
        self.handler.lambda_handler(self.event({"sessionId": SESSION, "message": "x"}), None)
        item = self.table.put_item.call_args_list[0].kwargs["Item"]
        self.assertIn("expires_at", item)

    def test_internal_error_response(self):
        self.table.query.side_effect = RuntimeError("boom")
        result = self.handler.lambda_handler(self.event({"sessionId": SESSION, "message": "x"}), None)
        self.assertEqual(result["statusCode"], 500)

    def test_unknown_model_citation_removed(self):
        self.table.query.return_value = {"Items": []}
        self.retrieval_response()
        self.model_response("Answer [1] [99].")
        result = self.handler.lambda_handler(self.event({"sessionId": SESSION, "message": "x"}), None)
        body = json.loads(result["body"])
        self.assertEqual(body["answer"], "Answer [1] .")

    def test_private_evidence_not_returned(self):
        citation = self.handler._citations([{"content": {"text": "abc"}, "score": 1, "location": {"s3Location": {"uri": "s3://b/documents/a.md"}}}])[0]
        self.assertIn("evidence", citation)
        answer, public = self.handler.filter_cited_sources("Answer [1].", [citation])
        self.assertEqual(answer, "Answer [1].")
        self.assertNotIn("evidence", public[0])
