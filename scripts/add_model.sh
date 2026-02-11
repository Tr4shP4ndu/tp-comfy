#!/usr/bin/env bash
#
# Add a model to the download list
# Usage: ./add_model.sh <url> <folder> [new_filename]
#
# Examples:
#   ./add_model.sh "https://example.com/model.safetensors" checkpoints
#   ./add_model.sh "https://example.com/model.safetensors" checkpoints "my_model.safetensors"

set -Eeuo pipefail

CONFIG_FILE="${CONFIG_FILE:-config/models.txt}"

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

# Valid model folders
VALID_FOLDERS=(
    "checkpoints"
    "clip"
    "clip_vision"
    "configs"
    "controlnet"
    "controlnet/flux"
    "diffusers"
    "diffusion_models"
    "embeddings"
    "gligen"
    "hypernetworks"
    "loras"
    "photomaker"
    "style_models"
    "unet"
    "upscale_models"
    "vae"
    "vae_approx"
    "sam2"
    "ultralytics/bbox"
    "ultralytics/segm"
    "mmdets"
    "onnx"
    "liveportrait"
)

function show_usage() {
    echo "Usage: $0 <url> <folder> [new_filename]"
    echo ""
    echo "Arguments:"
    echo "  url           - Direct download URL for the model"
    echo "  folder        - Target folder (see valid folders below)"
    echo "  new_filename  - Optional: rename the file (default: keep original name)"
    echo ""
    echo "Valid folders:"
    for folder in "${VALID_FOLDERS[@]}"; do
        echo "  - $folder"
    done
    echo ""
    echo "Examples:"
    echo "  $0 'https://huggingface.co/model.safetensors' checkpoints"
    echo "  $0 'https://civitai.com/model.safetensors' loras 'my_lora.safetensors'"
}

function extract_filename() {
    local url="$1"
    local filename
    
    # Remove query parameters and extract filename
    filename=$(basename "${url%%\?*}")
    
    # Handle some common URL patterns
    if [[ "$filename" == "download" ]] || [[ "$filename" =~ ^[0-9]+$ ]]; then
        # Can't extract meaningful filename
        echo ""
    else
        echo "$filename"
    fi
}

# Check arguments
if [ $# -lt 2 ]; then
    show_usage
    exit 1
fi

URL="$1"
FOLDER="$2"
NEW_NAME="${3:-}"

# Validate folder
folder_valid=false
for valid in "${VALID_FOLDERS[@]}"; do
    if [ "$FOLDER" = "$valid" ]; then
        folder_valid=true
        break
    fi
done

if [ "$folder_valid" = false ]; then
    echo -e "${RED}Error: Invalid folder '$FOLDER'${NC}"
    echo ""
    echo "Valid folders:"
    for folder in "${VALID_FOLDERS[@]}"; do
        echo "  - $folder"
    done
    exit 1
fi

# Determine output filename
if [ -n "$NEW_NAME" ]; then
    OUTPUT_PATH="$FOLDER/$NEW_NAME"
else
    EXTRACTED_NAME=$(extract_filename "$URL")
    if [ -z "$EXTRACTED_NAME" ]; then
        echo -e "${RED}Error: Could not extract filename from URL${NC}"
        echo "Please provide a filename as the third argument"
        exit 1
    fi
    OUTPUT_PATH="$FOLDER/$EXTRACTED_NAME"
fi

# Check if already exists in config
if grep -q "out=$OUTPUT_PATH" "$CONFIG_FILE" 2>/dev/null; then
    echo -e "${YELLOW}Warning: A model with output path '$OUTPUT_PATH' already exists in config${NC}"
    read -p "Add anyway? [y/N] " confirm
    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
        echo "Cancelled."
        exit 0
    fi
fi

# Add to config file
echo "" >> "$CONFIG_FILE"
echo "$URL" >> "$CONFIG_FILE"
echo "  out=$OUTPUT_PATH" >> "$CONFIG_FILE"

echo -e "${GREEN}Added model to $CONFIG_FILE:${NC}"
echo "  URL: $URL"
echo "  Output: $OUTPUT_PATH"
echo ""
echo -e "${YELLOW}Run 'make download-models' to download.${NC}"
