#!/usr/bin/env python3
import argparse
import hashlib
import json
from datetime import datetime, timedelta, timezone
from pathlib import Path

def sha256_file(path: str) -> str:
    digest = hashlib.sha256()
    with open(path, "rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def require(value: str, name: str) -> str:
    if value is None or str(value).strip() == "":
        raise SystemExit(f"missing required value: {name}")
    return str(value)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", default="metadata.json")
    parser.add_argument("--plan-file", required=True)
    parser.add_argument("--lockfile", required=True)
    parser.add_argument("--applyable", choices=["true", "false"], required=True)
    parser.add_argument("--event", required=True)
    parser.add_argument("--action", default="")
    parser.add_argument("--repository", required=True)
    parser.add_argument("--workflow-file", required=True)
    parser.add_argument("--workflow-run-id", required=True)
    parser.add_argument("--commit-sha", required=True)
    parser.add_argument("--head-branch", required=True)
    parser.add_argument("--default-branch", default="")
    parser.add_argument("--terraform-version", required=True)
    parser.add_argument("--state-key", required=True)
    parser.add_argument("--retention-days", type=int, default=3)
    args = parser.parse_args()

    now = datetime.now(timezone.utc).replace(microsecond=0)
    metadata = {
        "action": args.action,
        "applyable": args.applyable == "true",
        "commitSha": require(args.commit_sha, "commit-sha"),
        "createdAt": now.isoformat().replace("+00:00", "Z"),
        "defaultBranch": args.default_branch,
        "event": require(args.event, "event"),
        "expiresAt": (now + timedelta(days=args.retention_days)).isoformat().replace("+00:00", "Z"),
        "headBranch": require(args.head_branch, "head-branch"),
        "lockfileSha256": sha256_file(args.lockfile),
        "planSha256": sha256_file(args.plan_file),
        "repository": require(args.repository, "repository"),
        "schemaVersion": 1,
        "stateKey": require(args.state_key, "state-key"),
        "terraformVersion": require(args.terraform_version, "terraform-version"),
        "workflowFile": require(args.workflow_file, "workflow-file"),
        "workflowRunId": require(args.workflow_run_id, "workflow-run-id"),
    }

    Path(args.output).write_text(json.dumps(metadata, indent=2, sort_keys=True) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
