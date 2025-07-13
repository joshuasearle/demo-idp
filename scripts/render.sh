#!/usr/bin/env bash

set -euo pipefail

function main() {
  if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <environment>"
    exit 1
  fi

  local env="$1"

  if ! git checkout "env/$env" 2>/dev/null; then
    git checkout -b "env/$env"
  fi

  local addons_dir="addons/"
  local addons
  addons=$(find "$addons_dir" -type f -name "*.yaml" -exec basename {} .yaml \;)

  for addon in $addons; do
    local addon_metadata_file_path="addons/$addon.yaml"

    local addon_name
    addon_name=$(yq ".name" "$addon_metadata_file_path")
    local addon_repo_name
    addon_repo_name=$(yq ".repo.name" "$addon_metadata_file_path")
    local addon_repo_url
    addon_repo_url=$(yq ".repo.url" "$addon_metadata_file_path")
    local chart_name
    chart_name=$(yq ".chart.name" "$addon_metadata_file_path")
    local chart_version
    chart_version=$(yq ".chart.version" "$addon_metadata_file_path")

    if ! helm repo list | grep -q "$addon_repo_name"; then
      helm repo add "$addon_repo_name" "$addon_repo_url"
      helm repo update "$addon_repo_name"
    fi

    local chart_reference="$addon_repo_name/$chart_name"

    helm template "$addon_name" \
      "$chart_reference" \
      --namespace "$addon_name" \
      --create-namespace \
      --version "$chart_version" \
      --output-dir ./
  done
}

main "$@"
