SHELL := /bin/sh

.PHONY: fmt validate validate-core validate-application test audit-iam check-cost plan-core plan-application

fmt:
	terraform fmt -recursive

validate: fmt validate-core validate-application test audit-iam check-cost

validate-core:
	terraform -chdir=infra/stacks/core init -backend=false
	terraform -chdir=infra/stacks/core validate

validate-application:
	terraform -chdir=infra/stacks/application init -backend=false
	terraform -chdir=infra/stacks/application validate

test:
	python -m compileall src || true
	python -m unittest discover -s src/ingestion_lambda/tests || true
	python -m unittest discover -s src/query_lambda/tests || true
	python -m unittest discover -s scripts/tests || true
	@if command -v node >/dev/null 2>&1; then node --check frontend/app.js; else echo "node unavailable; skipped JS syntax check"; fi

audit-iam:
	python scripts/validate_iam.py

check-cost:
	python scripts/check_cost_guardrails.py

plan-core:
	test -n "$(BACKEND_CONFIG)" && test -n "$(TFVARS)"
	terraform -chdir=infra/stacks/core init -backend-config="$(BACKEND_CONFIG)"
	terraform -chdir=infra/stacks/core plan -var-file="$(TFVARS)" -out=core.tfplan

plan-application:
	test -n "$(BACKEND_CONFIG)" && test -n "$(TFVARS)"
	terraform -chdir=infra/stacks/application init -backend-config="$(BACKEND_CONFIG)"
	terraform -chdir=infra/stacks/application plan -var-file="$(TFVARS)" -out=application.tfplan
