#!/usr/bin/env bash

set -Eeuo pipefail

# Create necessary directories
mkdir -vp /data/{config,workflows,input,custom_nodes,output,models/{checkpoints,clip,clip_vision,configs,diffusers,diffusion_models,embeddings,gligen,hypernetworks,loras,photomaker,style_models,unet,upscale_models,vae,vae_approx,sam2,mmdets,onnx,liveportrait,ultralytics}}

function clone_or_pull () {
    if [[ $1 =~ ^(.*[/:])(.*)(\.git)$ ]] || [[ $1 =~ ^(http.*\/)(.*)$ ]]; then
        echo "${BASH_REMATCH[2]}"
        set +e
        git clone --depth=1 --no-tags --recurse-submodules --shallow-submodules "$1" || git -C "${BASH_REMATCH[2]}" pull --ff-only
        set -e
    else
        echo "[ERROR] Invalid URL: $1"
        return 1
    fi
}

cd /data/custom_nodes

echo "########################################"
echo "[INFO] Downloading Custom Nodes..."
echo "########################################"

# Add your repositories here
repos=(
    "https://github.com/ltdrdata/ComfyUI-Manager.git"
    "https://github.com/GHOSTLXH/ComfyUI-Counternodes.git"
    "https://github.com/yuvraj108c/ComfyUI_InvSR.git"
    "https://github.com/ssitu/ComfyUI_UltimateSDUpscale.git"
    "https://github.com/risunobushi/ComfyUI_DisplacementMapTools.git"
    "https://github.com/twri/sdxl_prompt_styler.git"
    "https://github.com/AInseven/ComfyUI-fastblend.git"
    "https://github.com/Suzie1/ComfyUI_Comfyroll_CustomNodes.git"
    "https://github.com/AIGODLIKE/AIGODLIKE-ComfyUI-Translation.git"
    "https://github.com/crystian/ComfyUI-Crystools.git"
    "https://github.com/crystian/ComfyUI-Crystools-save.git"
    "https://github.com/giriss/comfy-image-saver.git"
    "https://github.com/bash-j/mikey_nodes.git"
    "https://github.com/chrisgoringe/cg-use-everywhere.git"
    "https://github.com/cubiq/ComfyUI_essentials.git"
    "https://github.com/jags111/efficiency-nodes-comfyui.git"
    "https://github.com/kijai/ComfyUI-KJNodes.git"
    "https://github.com/pythongosssss/ComfyUI-Custom-Scripts.git"
    "https://github.com/shiimizu/ComfyUI_smZNodes.git"
    "https://github.com/GTSuya-Studio/ComfyUI-Gtsuya-Nodes.git"
    "https://github.com/daxcay/ComfyUI-JDCN.git"
    "https://github.com/aria1th/ComfyUI-LogicUtils.git"
    "https://github.com/shadowcz007/comfyui-mixlab-nodes.git"
    "https://github.com/TTPlanetPig/Comfyui_TTP_Toolset.git"
    "https://github.com/chrisgoringe/cg-image-picker.git"
    "https://github.com/lldacing/ComfyUI_PuLID_Flux_ll.git"
    "https://github.com/ssitu/ComfyUI_UltimateSDUpscale.git"
    "https://github.com/PowerHouseMan/ComfyUI-AdvancedLivePortrait.git"
    "https://github.com/theUpsider/ComfyUI-Logic.git"
    "https://github.com/sipie800/ComfyUI-PuLID-Flux-Enhanced.git"
    "https://github.com/rgthree/rgthree-comfy.git"
    "https://github.com/ltdrdata/ComfyUI-Impact-Subpack.git"
    "https://github.com/ltdrdata/ComfyUI-Impact-Pack.git"
    "https://github.com/yolain/ComfyUI-Easy-Use.git"
    "https://github.com/ssitu/ComfyUI_UltimateSDUpscale.git"
    "https://github.com/kijai/ComfyUI-depth-fm.git"
    "https://github.com/kijai/ComfyUI-Geowizard.git"
    "https://github.com/kijai/ComfyUI-Marigold.git"
    "https://github.com/picturesonpictures/comfy_PoP.git"
    "https://github.com/Derfuu/Derfuu_ComfyUI_ModdedNodes.git"
    "https://github.com/sipherxyz/comfyui-art-venture.git"
    "https://github.com/cubiq/ComfyUI_InstantID.git"
    "https://github.com/cubiq/ComfyUI_IPAdapter_plus.git"
    "https://github.com/Fannovel16/comfyui_controlnet_aux.git"
    "https://github.com/florestefano1975/comfyui-portrait-master.git"
    "https://github.com/huchenlei/ComfyUI-layerdiffuse.git"
    "https://github.com/mcmonkeyprojects/sd-dynamic-thresholding.git"
    "https://github.com/storyicon/comfyui_segment_anything.git"
    "https://github.com/twri/sdxl_prompt_styler.git"
    "https://github.com/KoreTeknology/ComfyUI-Universal-Styler.git"
    "https://github.com/kijai/ComfyUI-Florence2.git"
    "https://github.com/kijai/ComfyUI-LivePortraitKJ.git"
    "https://github.com/Fannovel16/ComfyUI-Frame-Interpolation.git"
    "https://github.com/FizzleDorf/ComfyUI_FizzNodes.git"
    "https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git"
    "https://github.com/melMass/comfy_mtb.git"
    "https://github.com/MrForExample/ComfyUI-AnimateAnyone-Evolved.git"
    "https://github.com/cubiq/ComfyUI_FaceAnalysis.git"
    "https://github.com/pythongosssss/ComfyUI-WD14-Tagger.git"
    "https://github.com/SLAPaper/ComfyUI-Image-Selector.git"
    "https://github.com/kijai/ComfyUI-segment-anything-2.git"
)

for repo in "${repos[@]}"; do
    clone_or_pull "$repo"
done

# Download files for /data/models
[[ -f /docker/models.txt ]] && aria2c -x 10 --disable-ipv6 --input-file /docker/models.txt --dir /data/models --continue

echo "All download processes completed."
