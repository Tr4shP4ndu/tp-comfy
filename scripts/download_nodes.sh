#!/usr/bin/env bash
#
# Download/update ComfyUI custom nodes
# Usage: ./download_nodes.sh <custom_nodes_directory> [config_file]

set -Eeuo pipefail

NODES_DIR="${1:-data/custom_nodes}"
CONFIG_FILE="${2:-config/nodes.txt}"

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

# Create directory if it doesn't exist
mkdir -p "$NODES_DIR"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Downloading/Updating Custom Nodes${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Nodes directory: $NODES_DIR"
echo "Config file: $CONFIG_FILE"
echo ""

function clone_or_pull() {
    local url="$1"
    local repo_name
    
    # Extract repository name from URL
    if [[ $url =~ ^(.*[/:])(.*)(\.git)$ ]]; then
        repo_name="${BASH_REMATCH[2]}"
    elif [[ $url =~ ^(http.*\/)(.*)$ ]]; then
        repo_name="${BASH_REMATCH[2]}"
    else
        echo -e "${RED}[ERROR] Invalid URL: $url${NC}"
        return 1
    fi
    
    cd "$NODES_DIR"
    
    if [ -d "$repo_name" ]; then
        echo -e "${YELLOW}Updating ${repo_name}...${NC}"
        git -C "$repo_name" pull --ff-only 2>/dev/null || echo -e "${YELLOW}  (already up to date or conflict)${NC}"
    else
        echo -e "${GREEN}Cloning ${repo_name}...${NC}"
        git clone --depth=1 --no-tags --recurse-submodules --shallow-submodules "$url" 2>/dev/null || {
            echo -e "${RED}  Failed to clone $repo_name${NC}"
            return 1
        }
    fi
}

# Check if config file exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${RED}Config file not found: $CONFIG_FILE${NC}"
    exit 1
fi

# Read repos from config file (skip comments and empty lines)
repos=()
while IFS= read -r line || [[ -n "$line" ]]; do
    # Skip empty lines and comments
    line=$(echo "$line" | sed 's/#.*//' | xargs)
    if [ -n "$line" ]; then
        repos+=("$line")
    fi
done < "$CONFIG_FILE"

echo "Found ${#repos[@]} repositories to process"
echo ""

# Process repositories
success_count=0
fail_count=0

for repo in "${repos[@]}"; do
    if clone_or_pull "$repo"; then
        ((success_count++)) || true
    else
        ((fail_count++)) || true
    fi
done

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Download Summary${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "Successful: ${GREEN}${success_count}${NC}"
echo -e "Failed: ${RED}${fail_count}${NC}"
echo ""
echo "Custom nodes are in: $NODES_DIR"
echo ""
echo -e "${YELLOW}Note: Run 'make install-node-deps' to install Python dependencies for custom nodes.${NC}"
