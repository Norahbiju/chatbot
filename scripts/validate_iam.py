import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LAMBDA_POLICY_FILES = [
    ROOT / "infra/modules/application/iam.tf",
]
BROAD_ACTIONS = ("bedrock:*", "s3:*", "dynamodb:*", "sqs:*", "logs:*")


def fail(message: str) -> None:
    raise SystemExit(message)


def main() -> None:
    for path in LAMBDA_POLICY_FILES:
        text = path.read_text(encoding="utf-8")
        lambda_blocks = re.findall(r'data "aws_iam_policy_document" "(?:ingestion_lambda|query_lambda)" \{([\s\S]*?)\n\}', text)
        for block in lambda_blocks:
            if 'resources = ["*"]' in block or "resources = [\"*\"]" in block:
                fail(f"Lambda policy in {path} contains Resource '*'")
            for action in BROAD_ACTIONS:
                if action in block:
                    fail(f"Lambda policy in {path} contains broad action {action}")
    print(json.dumps({"status": "ok", "checked": [str(p.relative_to(ROOT)) for p in LAMBDA_POLICY_FILES]}))


if __name__ == "__main__":
    main()
