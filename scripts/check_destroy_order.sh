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

echo "Destroy confirmation accepted for ${stack}."
