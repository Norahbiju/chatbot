#!/usr/bin/env python3
import argparse
import hashlib
import json
from datetime import datetime, timezone
from pathlib import Path

REQUIRED = {
    "schemaVersion",
    "applyable",
    "event",
    "action",
    "repository",
    "workflowFile",
    "workflowRunId",
    "stack",
    "environment",
    "commitSha",
    "defaultBranch",
    "terraformVersion",
    "stateKey",
    "planSha256",
    "lockfileSha256",
    "createdAt",
    "expiresAt",
}


def sha256_file(path: str) -> str:
    digest = hashlib.sha256()
    with open(path, "rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def fail(message: str) -> None:
    raise SystemExit(message)


def parse_time(value: str) -> datetime:
    return datetime.fromisoformat(value.replace("Z", "+00:00"))


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--metadata", default="metadata.json")
    parser.add_argument("--plan-file", required=True)
    parser.add_argument("--lockfile", required=True)
    parser.add_argument("--repository", required=True)
    parser.add_argument("--workflow-file", required=True)
    parser.add_argument("--workflow-run-id", required=True)
    parser.add_argument("--stack", required=True)
    parser.add_argument("--environment", required=True)
    parser.add_argument("--state-key", required=True)
    parser.add_argument("--default-branch", required=True)
    args = parser.parse_args()

    metadata = json.loads(Path(args.metadata).read_text(encoding="utf-8"))
    missing = sorted(REQUIRED - set(metadata))
    if missing:
        fail(f"metadata missing fields: {', '.join(missing)}")
    if metadata["schemaVersion"] != 1:
        fail("unsupported schema version")
    expected = {
        "repository": args.repository,
        "workflowFile": args.workflow_file,
        "workflowRunId": args.workflow_run_id,
        "stack": args.stack,
        "environment": args.environment,
        "stateKey": args.state_key,
        "defaultBranch": args.default_branch,
    }
    for key, value in expected.items():
        if metadata.get(key) != value:
            fail(f"metadata {key} mismatch")
    if metadata.get("applyable") is not True:
        fail("metadata is not applyable")
    if metadata.get("event") != "workflow_dispatch":
        fail("metadata event is not workflow_dispatch")
    if metadata.get("action") != "plan":
        fail("metadata action is not plan")
    if not metadata.get("commitSha"):
        fail("metadata commit SHA is missing")
    if parse_time(metadata["expiresAt"]) <= datetime.now(timezone.utc):
        fail("metadata artifact has expired")
    if sha256_file(args.plan_file) != metadata["planSha256"]:
        fail("plan checksum mismatch")
    if sha256_file(args.lockfile) != metadata["lockfileSha256"]:
        fail("lockfile checksum mismatch")
    print(json.dumps({"status": "ok", "stack": metadata["stack"], "environment": metadata["environment"]}))


if __name__ == "__main__":
    main()
