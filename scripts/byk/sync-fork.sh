#!/bin/bash

GREEN='\033[0;32m'
NC='\033[0m' # No Color

if ! git rev-parse --git-dir >/dev/null 2>&1; then
    echo "Error: Not a git repository"
    exit 1
else
    echo -e "${GREEN}✓${NC} Git repository detected"
fi

# Get the current repository's owner and name
REPO_INFO=$(gh repo view --json name,owner --jq '[.owner.login, .name] | join("/")' 2>/dev/null)

# Set default remote if not already set
if [ -z "$REPO_INFO" ]; then
    echo "ℹ️ No default remote set. Setting default remote..."
    # Get the current repository's owner and name from git remote
    REMOTE_URL=$(git remote get-url origin)
    REPO_PATH=$(echo "$REMOTE_URL" | sed -E 's/.*github.com(:|\/)(.*)\.git/\2/')

    if [ -n "$REPO_PATH" ]; then
        gh repo set-default "$REPO_PATH"
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✓${NC} Default remote set successfully for $REPO_PATH"
        else
            echo "Error: Failed to set default remote"
            exit 1
        fi
    else
        echo "Error: Could not determine repository path from remote URL"
        exit 1
    fi
else
    echo -e "${GREEN}✓${NC} Default remote already set for $REPO_INFO"
fi

# Ensure default remote is set for gh commands
echo "ℹ️ Setting default remote for GitHub CLI..."
DEFAULT_REMOTE=$(git remote get-url origin)
REPO_PATH=$(echo "$DEFAULT_REMOTE" | sed -E 's/.*github.com(:|\/)(.*)\.git/\2/')

# Force set default remote
gh repo set-default "$REPO_PATH"
if [ $? -ne 0 ]; then
    echo "Error: Failed to set default remote for GitHub CLI"
    exit 1
fi
echo -e "${GREEN}✓${NC} Default remote set for GitHub CLI: $REPO_PATH"

# Get remote URL and check if it's a fork of buerokratt
REMOTE_URL=$(git remote get-url origin)
UPSTREAM_URL=$(git remote get-url upstream 2>/dev/null)
echo "ℹ️ Remote URL: $REMOTE_URL"
echo "ℹ️ Upstream URL: $UPSTREAM_URL"

# Check if upstream points to buerokratt
if [[ "$UPSTREAM_URL" =~ github\.com(:|\/)buerokratt\/ ]]; then
    echo -e "${GREEN}✓${NC} Upstream points to buerokratt repository"
else
    # Check if it's a fork of buerokratt using GitHub API
    echo "ℹ️ Checking parent repository using GitHub API..."
    REPO_INFO=$(gh repo view --json parent 2>/dev/null)

    if [ -z "$REPO_INFO" ]; then
        echo "Error: Could not get repository information"
        exit 1
    fi

    echo "ℹ️ Repository info: $REPO_INFO"
    PARENT_ORG=$(echo "$REPO_INFO" | jq -r '.parent.owner.login')
    PARENT_REPO=$(echo "$REPO_INFO" | jq -r '.parent.name')

    if [ "$PARENT_ORG" == "null" ]; then
        echo "⚠️ Warning: This repository is not recognized as a fork by GitHub"
        echo "Even though you have an upstream remote configured, GitHub's API doesn't recognize this as a fork."
        echo "This might be a GitHub API issue. You can try:"
        echo "1. Waiting and trying again later"
        echo "2. Contacting GitHub support"
        exit 1
    fi

    echo "ℹ️ Parent repository: $PARENT_ORG/$PARENT_REPO"

    if [[ "$PARENT_ORG" != "buerokratt" ]]; then
        echo "Error: This repository is not a fork of buerokratt"
        exit 1
    fi
fi

# Sync the dev branch from upstream
echo "Syncing dev branch from upstream..."
gh repo sync --branch dev
if [ $? -ne 0 ]; then
    echo "⚠️ GitHub sync failed. Falling back to manual sync..."
    git fetch upstream dev
    git checkout dev
    git merge upstream/dev
    echo "✓ Manual sync completed"
else
    echo -e "${GREEN}✓${NC} GitHub sync completed"
fi

# Pull the latest dev branch and switch to it
echo "Pulling dev branch..."
git fetch origin dev
if [ $? -ne 0 ]; then
    echo "Error: Failed to fetch from origin"
    exit 1
fi

# Check if we're already on dev branch
CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" != "dev" ]; then
    git checkout dev
    if [ $? -ne 0 ]; then
        echo "Error: Failed to switch to dev branch"
        exit 1
    fi
fi

# Merge changes from origin/dev
git merge origin/dev
if [ $? -ne 0 ]; then
    echo "Error: Failed to merge changes from origin/dev"
    exit 1
fi

echo -e "${GREEN}✓${NC} Sync complete. You're now on the dev branch."
