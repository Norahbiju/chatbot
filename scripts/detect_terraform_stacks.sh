#!/usr/bin/env bash
set -Eeuo pipefail

base_ref="${1:-}"
head_ref="${2:-HEAD}"

if [[ -n "${GITHUB_EVENT_NAME:-}" && "${GITHUB_EVENT_NAME}" == "pull_request" && -n "${GITHUB_BASE_REF:-}" ]]; then
  base_ref="origin/${GITHUB_BASE_REF}"
fi

if [[ -z "${base_ref}" ]]; then
  if git rev-parse HEAD^ >/dev/null 2>&1; then
    base_ref="HEAD^"
  else
    base_ref="$(git hash-object -t tree /dev/null)"
  fi
fi

if ! git rev-parse "${base_ref}" >/dev/null 2>&1; then
  git fetch --no-tags --prune --depth=100 origin "${GITHUB_BASE_REF:-}" || true
fi

changed="$(git diff --name-only "${base_ref}" "${head_ref}" || git diff-tree --no-commit-id --name-only -r "${head_ref}")"

core=false
application=false

while IFS= read -r file; do
  [[ -z "${file}" ]] && continue
  case "${file}" in
    infra/stacks/core/*|src/ingestion_lambda/*|documents/*)
      core=true
      ;;
    infra/stacks/application/*|src/query_lambda/*|frontend/*)
      application=true
      ;;
    infra/modules/*|infra/environments/*|.terraform-version|.github/actions/terraform-bootstrap/*|.github/workflows/terraform.yml)
      core=true
      application=true
      ;;
    *.tf|*.tfvars|*.hcl)
      core=true
      application=true
      ;;
    README.md|ai_context/*|*.md)
      ;;
    *)
      ;;
  esac
done <<< "${changed}"

items=()
if [[ "${core}" == "true" ]]; then
  items+=('{"stack":"core","working_directory":"infra/stacks/core","tfvars":"infra/environments/dev/core.tfvars","state_suffix":"core/terraform.tfstate"}')
fi
if [[ "${application}" == "true" ]]; then
  items+=('{"stack":"application","working_directory":"infra/stacks/application","tfvars":"infra/environments/dev/application.tfvars","state_suffix":"application/terraform.tfstate"}')
fi

if [[ "${#items[@]}" -eq 0 ]]; then
  printf '{"include":[]}\n'
else
  joined="$(IFS=,; echo "${items[*]}")"
  printf '{"include":[%s]}\n' "${joined}"
fi
