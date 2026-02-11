#!/usr/bin/env bash
#
# Add a custom node repository to the download list
# Usage: ./add_node.sh <github_url>
#
# Examples:
#   ./add_node.sh "https://github.com/username/ComfyUI-NodeName.git"
#   ./add_node.sh "https://github.com/username/ComfyUI-NodeName"

set -Eeuo pipefail

CONFIG_FILE="${CONFIG_FILE:-setup/nodes.txt}"

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

function show_usage() {
    echo "Usage: $0 <github_url>"
    echo ""
    echo "Arguments:"
    echo "  github_url - GitHub repository URL for the custom node"
    echo ""
    echo "Examples:"
    echo "  $0 'https://github.com/username/ComfyUI-NodeName.git'"
    echo "  $0 'https://github.com/username/ComfyUI-NodeName'"
}

# Check arguments
if [ $# -lt 1 ]; then
    show_usage
    exit 1
fi

URL="$1"

# Normalize URL (add .git if missing)
if [[ ! "$URL" =~ \.git$ ]]; then
    URL="${URL}.git"
fi

# Validate it looks like a GitHub URL
if [[ ! "$URL" =~ ^https://github\.com/.+/.+\.git$ ]]; then
    echo -e "${RED}Error: URL doesn't look like a valid GitHub repository${NC}"
    echo "Expected format: https://github.com/username/repo-name.git"
    exit 1
fi

# Extract repo name for display
if [[ $URL =~ ^.*/(.*)\.git$ ]]; then
    REPO_NAME="${BASH_REMATCH[1]}"
else
    REPO_NAME="$URL"
fi

# Check if already exists in config
if grep -qF "$URL" "$CONFIG_FILE" 2>/dev/null; then
    echo -e "${YELLOW}Node '$REPO_NAME' already exists in config${NC}"
    exit 0
fi

# Add to config file
echo "$URL" >> "$CONFIG_FILE"

echo -e "${GREEN}Added node to $CONFIG_FILE:${NC}"
echo "  Repository: $REPO_NAME"
echo "  URL: $URL"
echo ""
echo -e "${YELLOW}Run 'make download-nodes' to download.${NC}"
