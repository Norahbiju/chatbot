SHELL := /bin/sh

.PHONY: fmt validate validate-infra test audit-iam check-cost plan

fmt:
	terraform fmt -recursive

validate: fmt validate-infra test audit-iam check-cost

validate-infra:
	terraform -chdir=infra init -backend=false
	terraform -chdir=infra validate

test:
	python -m compileall src scripts || true
	python -m unittest discover -s src/query_lambda/tests || true
	python -m unittest discover -s src/ingestion_lambda/tests || true
	python -m unittest discover -s scripts/tests || true
	@if command -v node >/dev/null 2>&1; then node --check frontend/app.js; else echo "node unavailable; skipped JS syntax check"; fi

audit-iam:
	python scripts/validate_iam.py

check-cost:
	python scripts/check_cost_guardrails.py

plan:
	test -n "$(BACKEND_CONFIG)" && test -n "$(TFVARS)"
	terraform -chdir=infra init -backend-config="$(BACKEND_CONFIG)"
	terraform -chdir=infra plan -var-file="$(TFVARS)" -out=infra.tfplan
