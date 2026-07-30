#!/usr/bin/env bash
set -Eeuo pipefail

confirmation="${1:?destroy confirmation is required}"

expected="DESTROY"
if [[ "${confirmation}" != "${expected}" ]]; then
  echo "Destroy confirmation must exactly equal: ${expected}" >&2
  exit 1
fi

echo "Destroy confirmation accepted."
