#!/usr/bin/env bash
set -x

# Default settings (latest drupal core)
if [ -z "$DP_PROJECT_TYPE" ]; then
    DP_PROJECT_TYPE=project_core
fi

if [ -z "$DP_PROJECT_NAME" ]; then
    DP_PROJECT_NAME=drupal
fi

# Set WORK_DIR
if [ "$DP_PROJECT_TYPE" == "project_core" ]; then
    RELATIVE_WORK_DIR=repos
    WORK_DIR="${GITPOD_REPO_ROOT}"/"$RELATIVE_WORK_DIR"
elif [ "$DP_PROJECT_TYPE" == "project_module" ]; then
    RELATIVE_WORK_DIR=web/modules/contrib
    WORK_DIR="${GITPOD_REPO_ROOT}"/"$RELATIVE_WORK_DIR"
    mkdir -p "${WORK_DIR}"
elif [ "$DP_PROJECT_TYPE" == "project_theme" ]; then
    RELATIVE_WORK_DIR=web/themes/contrib
    WORK_DIR="${GITPOD_REPO_ROOT}"/"$RELATIVE_WORK_DIR"
    mkdir -p "${WORK_DIR}"
fi

# Clone project
if [ ! -d "${WORK_DIR}"/"$DP_PROJECT_NAME" ]; then
    cd "$WORK_DIR" && git clone https://git.drupalcode.org/project/"$DP_PROJECT_NAME"
fi

# Dynamically generate .gitmodules file
RELATIVE_WORK_DIR=$RELATIVE_WORK_DIR/$DP_PROJECT_NAME
cat <<GITMODULESEND > .gitmodules
# This file was dynamically generated by a script
[submodule "$DP_PROJECT_NAME"]
    path = $RELATIVE_WORK_DIR
    url = https://git.drupalcode.org/project/$DP_PROJECT_NAME.git
    ignore = dirty
GITMODULESEND

WORK_DIR="${GITPOD_REPO_ROOT}"/$RELATIVE_WORK_DIR

# Checkout specific branch only if there's issue_fork
if [ -n "$DP_ISSUE_FORK" ]; then
    # If branch already exist only run checkout,
    if cd "${WORK_DIR}" && git show-ref -q --heads "$DP_ISSUE_BRANCH"; then
        cd "${WORK_DIR}" && git checkout "$DP_ISSUE_BRANCH"
    else
        cd "${WORK_DIR}" && git remote add "$DP_ISSUE_FORK" git@git.drupal.org:issue/"$DP_ISSUE_FORK".git
        cd "${WORK_DIR}" && git fetch "$DP_ISSUE_FORK"
        cd "${WORK_DIR}" && git checkout -b "$DP_ISSUE_BRANCH" --track "$DP_ISSUE_FORK"/"$DP_ISSUE_BRANCH"
    fi
fi

# If project type is NOT core, change Drupal core version
if [ "$DP_PROJECT_TYPE" != "project_core" ]; then
    cd "${GITPOD_REPO_ROOT}"/repos/drupal && git checkout "${DP_CORE_VERSION}"
fi

if [ -n "$DP_PATCH_FILE" ]; then
    echo Applying selected patch "$DP_PATCH_FILE"
    cd "${WORK_DIR}" && curl "$DP_PATCH_FILE" | patch -p1
fi

# Ignore specific directories during Drupal core development
cp "${GITPOD_REPO_ROOT}"/.gitpod/drupal/git-exclude.template "${GITPOD_REPO_ROOT}"/.git/info/exclude
cp "${GITPOD_REPO_ROOT}"/.gitpod/drupal/git-exclude.template "${GITPOD_REPO_ROOT}"/repos/drupal/.git/info/exclude

# Run composer update to prevent errors when Drupal core major version changed since last composer install
ddev composer update

# Run site install using a Drupal profile if one was defined
if [ -n "$DP_INSTALL_PROFILE" ] && [ "$DP_INSTALL_PROFILE" != "''" ]; then
    ddev drush si "$DP_INSTALL_PROFILE" -y
fi
