#!/usr/bin/env bash

set -euo pipefail

function main() {
  if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <environment>"
    exit 1
  fi

  local env="$1"

  kind create cluster --name "$env"

  helm repo add argocd https://argoproj.github.io/argo-helm
  helm repo update argocd
  helm install argocd argocd/argo-cd \
    --namespace argocd \
    --create-namespace \
    --version 8.1.3
}

main "$@"
