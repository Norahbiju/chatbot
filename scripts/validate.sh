#!/usr/bin/env sh
set -eu

terraform fmt -check -recursive
terraform -chdir=infra init -backend=false
terraform -chdir=infra validate

if command -v python >/dev/null 2>&1; then
  python -m compileall src scripts
  python -m unittest discover -s src/ingestion_lambda/tests
  python -m unittest discover -s src/query_lambda/tests
  python -m unittest discover -s scripts/tests
  python scripts/validate_iam.py
  python scripts/check_cost_guardrails.py
else
  echo "python unavailable; Python compile, unit tests, IAM audit, and cost audit remain unverified" >&2
  exit 1
fi

if command -v node >/dev/null 2>&1; then
  node --check frontend/app.js
else
  echo "node unavailable; skipped JavaScript syntax check"
fi
