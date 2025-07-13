#!/usr/bin/env bash

set -euo pipefail

function main() {
  if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <environment>"
    exit 1
  fi

  local env="$1"

  kind delete cluster --name "$env"
}

main "$@"
