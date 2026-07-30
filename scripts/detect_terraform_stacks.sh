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

infra_changed=false

while IFS= read -r file; do
  [[ -z "${file}" ]] && continue
  case "${file}" in
    infra/*|src/*|frontend/*|documents/*|.terraform-version|.github/actions/terraform-bootstrap/*|.github/actions/repo-validate/*|.github/actions/terraform-plan/*|.github/actions/restore-plan-artifact/*|.github/workflows/terraform-pr-plan.yml|.github/workflows/terraform-dispatch.yml)
      infra_changed=true
      ;;
    *.tf|*.tfvars|*.hcl)
      infra_changed=true
      ;;
    README.md|ai_context/*|*.md)
      ;;
    *)
      ;;
  esac
done <<< "${changed}"

items=()
if [[ "${infra_changed}" == "true" ]]; then
  items+=('{"stack":"infra","working_directory":"infra","tfvars":"infra/terraform.tfvars","state_suffix":"terraform.tfstate"}')
fi

if [[ "${#items[@]}" -eq 0 ]]; then
  printf '{"include":[]}\n'
else
  joined="$(IFS=,; echo "${items[*]}")"
  printf '{"include":[%s]}\n' "${joined}"
fi
