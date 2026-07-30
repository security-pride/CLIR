#!/usr/bin/env bash
set -Eeuo pipefail

# Backward-compatible wrapper. The Docker image invokes entrypoint.sh directly.
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
if [[ "$#" -eq 0 ]]; then
    set -- help
fi
exec "${SCRIPT_DIR}/scripts/entrypoint.sh" "$@"
