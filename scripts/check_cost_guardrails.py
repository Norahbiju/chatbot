import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TEXT = "\n".join(p.read_text(encoding="utf-8", errors="ignore") for p in (ROOT / "infra").rglob("*.tf"))

FORBIDDEN = {
    "aws_nat_gateway": "NAT Gateway",
    "opensearch": "OpenSearch",
    "aws_rds": "RDS/Aurora",
    "aws_kms_key": "customer-managed KMS key",
    "provisioned_throughput": "provisioned Bedrock throughput",
}

REQUIRED = {
    "aws_budgets_budget": "monthly budget",
    "throttling_rate_limit": "API throttling",
    "reserved_concurrent_executions": "Lambda reserved concurrency",
    "retention_in_days = 7": "short log retention",
    "billing_mode   = \"PROVISIONED\"": "DynamoDB provisioned billing",
    "default = 4": "small retrieval result count",
    "default = 500": "maximum generation tokens",
    "aws_s3_bucket_lifecycle_configuration": "S3 lifecycle rules",
}


def main() -> None:
    failures = []
    lower = TEXT.lower()
    for needle, label in FORBIDDEN.items():
        if needle in lower:
            failures.append(f"Forbidden cost item found: {label}")
    for needle, label in REQUIRED.items():
        if needle not in TEXT:
            failures.append(f"Required guardrail missing: {label}")
    if "read_capacity  = var.read_capacity" not in TEXT or "default = 5" not in TEXT:
        failures.append("DynamoDB default 5/5 capacity not evident")
    if failures:
        raise SystemExit("\n".join(failures))
    print(json.dumps({"status": "ok", "guardrails": list(REQUIRED.values())}))


if __name__ == "__main__":
    main()
