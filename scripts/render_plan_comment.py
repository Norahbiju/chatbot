#!/usr/bin/env python3
import argparse
import json
import re
from pathlib import Path

MAX_PLAN_CHARS = 45000


def summary(plan_text: str) -> str:
    match = re.search(r"Plan: (\d+) to add, (\d+) to change, (\d+) to destroy\.", plan_text)
    if match:
        return f"{match.group(1)} add, {match.group(2)} change, {match.group(3)} destroy"
    if "No changes." in plan_text:
        return "0 add, 0 change, 0 destroy"
    return "summary unavailable"


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--metadata", required=True)
    parser.add_argument("--plan-text", required=True)
    parser.add_argument("--artifact-name", required=True)
    parser.add_argument("--run-url", required=True)
    parser.add_argument("--status", required=True)
    parser.add_argument("--bootstrap-blocked", action="store_true")
    parser.add_argument("--output", required=True)
    args = parser.parse_args()

    metadata = json.loads(Path(args.metadata).read_text(encoding="utf-8"))
    plan = Path(args.plan_text).read_text(encoding="utf-8", errors="replace")
    truncated = len(plan) > MAX_PLAN_CHARS
    shown = plan[:MAX_PLAN_CHARS]
    banner = "APPLYABLE MANUAL PLAN" if metadata.get("applyable") else "SPECULATIVE PLAN - NOT ELIGIBLE FOR APPLY"
    blocker = ""
    if args.bootstrap_blocked:
        blocker = "\n\nThe application plan is blocked because the core stack has not yet created the required SSM parameters. Apply the core stack first, then rerun the plan.\n"
    note = "\n\nPlan output was truncated. Download the artifact for the complete output." if truncated else ""
    body = f"""<!-- terraform-plan -->
## Terraform Plan

**{banner}**

- Commit: `{metadata['commitSha']}`
- Status: `{args.status}`
- Summary: `{summary(plan)}`
- Artifact: `{args.artifact_name}`
- Workflow run: {args.run_url}
- Plan SHA-256: `{metadata['planSha256']}`
- Applyable: `{str(metadata.get('applyable')).lower()}`
{blocker}
<details>
<summary>Readable plan</summary>

```terraform
{shown}
```

</details>{note}
"""
    Path(args.output).write_text(body, encoding="utf-8")


if __name__ == "__main__":
    main()
