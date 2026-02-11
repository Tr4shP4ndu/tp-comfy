#!/usr/bin/env bash
#
# Download/update ComfyUI custom nodes
# Usage: ./download_nodes.sh <custom_nodes_directory>

set -Eeuo pipefail

NODES_DIR="${1:-data/custom_nodes}"

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

# Create directory if it doesn't exist
mkdir -p "$NODES_DIR"
cd "$NODES_DIR"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Downloading/Updating Custom Nodes${NC}"
echo -e "${GREEN}========================================${NC}"

function clone_or_pull() {
    local url="$1"
    local repo_name
    
    # Extract repository name from URL
    if [[ $url =~ ^(.*[/:])(.*)(\.git)$ ]] || [[ $url =~ ^(http.*\/)(.*)$ ]]; then
        repo_name="${BASH_REMATCH[2]}"
    else
        echo -e "${RED}[ERROR] Invalid URL: $url${NC}"
        return 1
    fi
    
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

# Custom node repositories
repos=(
    # Manager & Core
    "https://github.com/ltdrdata/ComfyUI-Manager.git"
    "https://github.com/ltdrdata/ComfyUI-Impact-Pack.git"
    "https://github.com/ltdrdata/ComfyUI-Impact-Subpack.git"
    
    # Utility Nodes
    "https://github.com/pythongosssss/ComfyUI-Custom-Scripts.git"
    "https://github.com/rgthree/rgthree-comfy.git"
    "https://github.com/chrisgoringe/cg-use-everywhere.git"
    "https://github.com/chrisgoringe/cg-image-picker.git"
    "https://github.com/crystian/ComfyUI-Crystools.git"
    "https://github.com/crystian/ComfyUI-Crystools-save.git"
    "https://github.com/cubiq/ComfyUI_essentials.git"
    "https://github.com/kijai/ComfyUI-KJNodes.git"
    "https://github.com/Suzie1/ComfyUI_Comfyroll_CustomNodes.git"
    "https://github.com/jags111/efficiency-nodes-comfyui.git"
    "https://github.com/yolain/ComfyUI-Easy-Use.git"
    "https://github.com/bash-j/mikey_nodes.git"
    "https://github.com/Derfuu/Derfuu_ComfyUI_ModdedNodes.git"
    "https://github.com/theUpsider/ComfyUI-Logic.git"
    "https://github.com/aria1th/ComfyUI-LogicUtils.git"
    "https://github.com/GHOSTLXH/ComfyUI-Counternodes.git"
    "https://github.com/daxcay/ComfyUI-JDCN.git"
    "https://github.com/GTSuya-Studio/ComfyUI-Gtsuya-Nodes.git"
    "https://github.com/TTPlanetPig/Comfyui_TTP_Toolset.git"
    "https://github.com/shadowcz007/comfyui-mixlab-nodes.git"
    
    # Image Saving & Output
    "https://github.com/giriss/comfy-image-saver.git"
    "https://github.com/SLAPaper/ComfyUI-Image-Selector.git"
    
    # Prompt & Styling
    "https://github.com/twri/sdxl_prompt_styler.git"
    "https://github.com/shiimizu/ComfyUI_smZNodes.git"
    "https://github.com/florestefano1975/comfyui-portrait-master.git"
    "https://github.com/KoreTeknology/ComfyUI-Universal-Styler.git"
    
    # Upscaling
    "https://github.com/ssitu/ComfyUI_UltimateSDUpscale.git"
    "https://github.com/yuvraj108c/ComfyUI_InvSR.git"
    
    # ControlNet & Depth
    "https://github.com/Fannovel16/comfyui_controlnet_aux.git"
    "https://github.com/kijai/ComfyUI-depth-fm.git"
    "https://github.com/kijai/ComfyUI-Geowizard.git"
    "https://github.com/kijai/ComfyUI-Marigold.git"
    "https://github.com/risunobushi/ComfyUI_DisplacementMapTools.git"
    
    # Face & Portrait
    "https://github.com/cubiq/ComfyUI_InstantID.git"
    "https://github.com/cubiq/ComfyUI_IPAdapter_plus.git"
    "https://github.com/cubiq/ComfyUI_FaceAnalysis.git"
    "https://github.com/lldacing/ComfyUI_PuLID_Flux_ll.git"
    "https://github.com/sipie800/ComfyUI-PuLID-Flux-Enhanced.git"
    "https://github.com/PowerHouseMan/ComfyUI-AdvancedLivePortrait.git"
    "https://github.com/kijai/ComfyUI-LivePortraitKJ.git"
    
    # Segmentation & Detection
    "https://github.com/storyicon/comfyui_segment_anything.git"
    "https://github.com/kijai/ComfyUI-segment-anything-2.git"
    
    # Video & Animation
    "https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git"
    "https://github.com/Fannovel16/ComfyUI-Frame-Interpolation.git"
    "https://github.com/FizzleDorf/ComfyUI_FizzNodes.git"
    "https://github.com/AInseven/ComfyUI-fastblend.git"
    "https://github.com/MrForExample/ComfyUI-AnimateAnyone-Evolved.git"
    
    # Florence & Vision
    "https://github.com/kijai/ComfyUI-Florence2.git"
    "https://github.com/pythongosssss/ComfyUI-WD14-Tagger.git"
    
    # Layer & Advanced
    "https://github.com/huchenlei/ComfyUI-layerdiffuse.git"
    "https://github.com/mcmonkeyprojects/sd-dynamic-thresholding.git"
    "https://github.com/sipherxyz/comfyui-art-venture.git"
    "https://github.com/picturesonpictures/comfy_PoP.git"
    "https://github.com/melMass/comfy_mtb.git"
    
    # Translation
    "https://github.com/AIGODLIKE/AIGODLIKE-ComfyUI-Translation.git"
)

echo ""
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
