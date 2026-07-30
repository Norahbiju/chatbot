#!/usr/bin/env bash
set -Eeuo pipefail

stack="${1:?stack is required}"
environment="${2:?environment is required}"
confirmation="${3:?destroy confirmation is required}"

expected="DESTROY ${environment} ${stack}"
if [[ "${confirmation}" != "${expected}" ]]; then
  echo "Destroy confirmation must exactly equal: ${expected}" >&2
  exit 1
fi

if [[ "${CHECK_STATE:-true}" == "false" ]]; then
  echo "Destroy confirmation accepted for ${stack}."
  exit 0
fi

if [[ "${stack}" != "core" ]]; then
  echo "Destroy order check passed for ${stack}."
  exit 0
fi

app_dir="${APPLICATION_WORKING_DIRECTORY:-infra/stacks/application}"
if [[ ! -d "${app_dir}" ]]; then
  echo "Application Terraform directory not found: ${app_dir}" >&2
  exit 1
fi

if terraform -chdir="${app_dir}" state list > "${RUNNER_TEMP:-/tmp}/application-state.txt"; then
  if [[ -s "${RUNNER_TEMP:-/tmp}/application-state.txt" ]]; then
    echo "Core destroy is blocked because application state still has managed resources." >&2
    echo "Destroy the application stack first, then rerun core destroy." >&2
    cat "${RUNNER_TEMP:-/tmp}/application-state.txt" >&2
    exit 1
  fi
else
  echo "Unable to inspect application state; refusing to destroy core." >&2
  exit 1
fi

echo "Destroy order check passed for core."
