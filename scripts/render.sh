#!/usr/bin/env bash

set -euo pipefail

function main() {
  if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <environment>"
    exit 1
  fi

  local env="$1"

  local build_dir
  build_dir=$(mktemp --directory)

  local addons_dir="addons/"
  local addons
  addons=$(find "$addons_dir" -type f -name "*.yaml" -exec basename {} .yaml \;)

  for addon in $addons; do
    local addon_metadata_file_path="addons/$addon.yaml"

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

    mkdir -p "$build_dir/$addon"
    helm template "$addon" \
      "$chart_reference" \
      --namespace "$addon" \
      --create-namespace \
      --version "$chart_version" \
      > "$build_dir/$addon/manifest.yaml"
  done

  git stash
  git checkout "env/$env"

  cp -r "$build_dir/"* .

  git add .
  git commit -m "Render addons for environment: $env"

  git checkout main
  git stash pop

  rm -rf "$build_dir"
}

main "$@"
