import hashlib
import json
import logging
import os
from typing import Any, Dict, List

import boto3
from botocore.exceptions import ClientError

LOG = logging.getLogger()
LOG.setLevel(logging.INFO)

ACTIVE_STATUSES = {"STARTING", "IN_PROGRESS"}
TEMPORARY_CODES = {"ThrottlingException", "TooManyRequestsException", "ConflictException", "InternalServerException", "ServiceUnavailableException"}

bedrock_agent = boto3.client("bedrock-agent")


def _log(event: str, **fields: Any) -> None:
    LOG.info(json.dumps({"event": event, **fields}, separators=(",", ":")))


def _extract_s3_key(record: Dict[str, Any]) -> str:
    body = json.loads(record["body"])
    detail = body.get("detail") or {}
    return detail.get("object", {}).get("key", "")


def _batch_failures(records: List[Dict[str, Any]]) -> List[Dict[str, str]]:
    return [{"itemIdentifier": record.get("messageId", "unknown")} for record in records if record.get("messageId")]


def _has_active_job(knowledge_base_id: str, data_source_id: str) -> bool:
    response = bedrock_agent.list_ingestion_jobs(
        knowledgeBaseId=knowledge_base_id,
        dataSourceId=data_source_id,
        maxResults=5,
    )
    return any(job.get("status") in ACTIVE_STATUSES for job in response.get("ingestionJobSummaries", []))


def _start_job(knowledge_base_id: str, data_source_id: str, keys: List[str]) -> None:
    digest = hashlib.sha256("\n".join(sorted(keys)).encode("utf-8")).hexdigest()
    kwargs = {
        "knowledgeBaseId": knowledge_base_id,
        "dataSourceId": data_source_id,
        "description": "S3 document change ingestion",
        "clientToken": digest,
    }
    bedrock_agent.start_ingestion_job(**kwargs)


def _is_temporary(exc: ClientError) -> bool:
    return exc.response.get("Error", {}).get("Code") in TEMPORARY_CODES


def lambda_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    knowledge_base_id = os.environ["KNOWLEDGE_BASE_ID"]
    data_source_id = os.environ["DATA_SOURCE_ID"]
    prefix = os.environ.get("DOCUMENT_PREFIX", "documents/")
    failures = []
    candidate_keys: List[str] = []

    for record in event.get("Records", []):
        message_id = record.get("messageId", "unknown")
        try:
            key = _extract_s3_key(record)
            if not key.startswith(prefix):
                _log("ignored_key", message_id=message_id)
                continue
            candidate_keys.append(key)
        except (json.JSONDecodeError, KeyError, TypeError) as exc:
            _log("malformed_message", message_id=message_id, error=type(exc).__name__)
            failures.append({"itemIdentifier": message_id})

    if not candidate_keys:
        return {"batchItemFailures": failures}

    try:
        if _has_active_job(knowledge_base_id, data_source_id):
            _log("active_ingestion_exists", changed_objects=len(candidate_keys))
            failures.extend(_batch_failures(event.get("Records", [])))
        else:
            _start_job(knowledge_base_id, data_source_id, candidate_keys)
            _log("ingestion_started", changed_objects=len(candidate_keys))
    except ClientError as exc:
        code = exc.response.get("Error", {}).get("Code", "Unknown")
        _log("bedrock_error", code=code, retryable=_is_temporary(exc))
        if _is_temporary(exc):
            failures.extend(_batch_failures(event.get("Records", [])))
        else:
            failures.extend(_batch_failures(event.get("Records", [])))

    return {"batchItemFailures": failures}
