import importlib
import json
import os
import unittest
from unittest.mock import Mock, patch

from botocore.exceptions import ClientError


def record(message_id="m1", key="documents/a.md"):
    return {
        "messageId": message_id,
        "body": json.dumps({
            "detail": {
                "bucket": {"name": "bucket"},
                "object": {"key": key},
            }
        }),
    }


class IngestionTests(unittest.TestCase):
    def setUp(self):
        os.environ["KNOWLEDGE_BASE_ID"] = "kb-123"
        os.environ["DATA_SOURCE_ID"] = "ds-123"
        os.environ["DOCUMENT_PREFIX"] = "documents/"
        with patch("boto3.client") as client:
            self.client = Mock()
            client.return_value = self.client
            import src.ingestion_lambda.handler as handler
            self.handler = importlib.reload(handler)
            self.handler.bedrock_agent = self.client

    def test_valid_object_created_event_starts_job(self):
        self.client.list_ingestion_jobs.return_value = {"ingestionJobSummaries": []}
        result = self.handler.lambda_handler({"Records": [record()]}, None)
        self.assertEqual(result, {"batchItemFailures": []})
        self.client.start_ingestion_job.assert_called_once()
        self.assertGreaterEqual(len(self.client.start_ingestion_job.call_args.kwargs["clientToken"]), 33)

    def test_multiple_events_one_batch(self):
        self.client.list_ingestion_jobs.return_value = {"ingestionJobSummaries": []}
        self.handler.lambda_handler({"Records": [record("m1"), record("m2", "documents/b.md")]}, None)
        self.assertEqual(self.client.start_ingestion_job.call_count, 1)

    def test_event_outside_prefix(self):
        result = self.handler.lambda_handler({"Records": [record(key="other/a.md")]}, None)
        self.assertEqual(result, {"batchItemFailures": []})
        self.client.start_ingestion_job.assert_not_called()

    def test_existing_active_ingestion_job_retries_batch(self):
        self.client.list_ingestion_jobs.return_value = {"ingestionJobSummaries": [{"status": "IN_PROGRESS"}]}
        result = self.handler.lambda_handler({"Records": [record("m1")]}, None)
        self.assertEqual(result["batchItemFailures"], [{"itemIdentifier": "m1"}])

    def test_bedrock_throttling_retries(self):
        self.client.list_ingestion_jobs.side_effect = ClientError({"Error": {"Code": "ThrottlingException"}}, "ListIngestionJobs")
        result = self.handler.lambda_handler({"Records": [record("m1")]}, None)
        self.assertEqual(result["batchItemFailures"], [{"itemIdentifier": "m1"}])

    def test_malformed_sqs_message(self):
        result = self.handler.lambda_handler({"Records": [{"messageId": "bad", "body": "{"}]}, None)
        self.assertEqual(result["batchItemFailures"], [{"itemIdentifier": "bad"}])

    def test_partial_batch_failure_response(self):
        self.client.list_ingestion_jobs.return_value = {"ingestionJobSummaries": []}
        result = self.handler.lambda_handler({"Records": [record("ok"), {"messageId": "bad", "body": "{"}]}, None)
        self.assertEqual(result["batchItemFailures"], [{"itemIdentifier": "bad"}])
