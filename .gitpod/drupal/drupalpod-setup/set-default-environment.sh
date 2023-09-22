#!/usr/bin/env bash
if [ -n "$DEBUG_SCRIPT" ]; then
    set -x
fi

# Load default envs
export "$(grep -v '^#' "$GITPOD_REPO_ROOT"/.env | xargs -d '\n')"

# Restoring Umami installation
cd "$GITPOD_REPO_ROOT" && ddev snapshot restore demo_umami

# Clone Drupal core repo
mkdir -p "${GITPOD_REPO_ROOT}"/repos
cd "${GITPOD_REPO_ROOT}"/repos && time git clone https://git.drupalcode.org/project/drupal
