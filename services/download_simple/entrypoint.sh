#!/usr/bin/env bash

set -Eeuo pipefail

# Create necessary directories
mkdir -vp /data_simple/{config,workflows,input,custom_nodes,output,models/{checkpoints,clip,clip_vision,configs,controlnet,diffusers,diffusion_models,embeddings,gligen,hypernetworks,loras,photomaker,style_models,unet,upscale_models,vae,vae_approx,sam2,mmdets,onnx,liveportrait,ultralytics}}

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

cd /data_simple/custom_nodes

echo "########################################"
echo "[INFO] Downloading Custom Nodes..."
echo "########################################"

# Add your repositories here
repos=(
    "https://github.com/ltdrdata/ComfyUI-Manager.git"
    "https://github.com/chrisgoringe/cg-image-filter.git"
    "https://github.com/ssitu/ComfyUI_UltimateSDUpscale.git"
    "https://github.com/Aksaz/comfyui-seamless-clone.git"
    "https://github.com/spacepxl/ComfyUI-HQ-Image-Save.git"
    "https://github.com/Conor-Collins/coco_tools.git"
    "https://github.com/sipherxyz/comfyui-art-venture.git"
    "https://github.com/Fannovel16/comfyui_controlnet_aux.git"
    "https://github.com/ltdrdata/ComfyUI-Impact-Pack.git"
    "https://github.com/ltdrdata/ComfyUI-Impact-Subpack.git"
    "https://github.com/kijai/ComfyUI-DepthAnythingV2.git"
    "https://github.com/kijai/ComfyUI-KJNodes.git"
    "https://github.com/crystian/ComfyUI-Crystools.git"
    "https://github.com/Kosinkadink/ComfyUI-AnimateDiff-Evolved.git"
    "https://github.com/Kosinkadink/ComfyUI-Advanced-ControlNet.git"
    "https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git"
    "https://github.com/cubiq/ComfyUI_IPAdapter_plus.git"
    "https://github.com/FizzleDorf/ComfyUI_FizzNodes.git"
    "https://github.com/rgthree/rgthree-comfy.git"
    "https://github.com/mcmonkeyprojects/sd-dynamic-thresholding.git"
    "https://github.com/Fannovel16/ComfyUI-Frame-Interpolation.git"
    "https://github.com/BlenderNeko/ComfyUI_ADV_CLIP_emb.git"
    "https://github.com/PowerHouseMan/ComfyUI-AdvancedLivePortrait.git"
    "https://github.com/chrisgoringe/cg-use-everywhere.git"
    "https://github.com/kijai/ComfyUI-HunyuanVideoWrapper.git"
    "https://github.com/kijai/ComfyUI-Hunyuan3DWrapper.git"
    "https://github.com/WASasquatch/was-node-suite-comfyui.git"
    "https://github.com/cubiq/ComfyUI_essentials.git"
    "https://github.com/ltdrdata/ComfyUI-Inspire-Pack.git"
    "https://github.com/theUpsider/ComfyUI-Logic.git"
    "https://github.com/Suzie1/ComfyUI_Comfyroll_CustomNodes.git"
    "https://github.com/jamesWalker55/comfyui-various.git"
    "https://github.com/if-ai/ComfyUI-IF_Trellis.git"
    "https://github.com/pythongosssss/ComfyUI-Custom-Scripts.git"
    "https://github.com/melMass/comfy_mtb.git"
    "https://github.com/kijai/ComfyUI-Marigold.git"
    "https://github.com/BadCafeCode/masquerade-nodes-comfyui.git"
    "https://github.com/kijai/ComfyUI-Geowizard.git"
    "https://github.com/kijai/ComfyUI-depth-fm.git"
    "https://github.com/picturesonpictures/comfy_PoP.git"
    "https://github.com/ALatentPlace/ComfyUI_yanc.git"
    "https://github.com/tudal/Hakkun-ComfyUI-nodes.git"
    "https://github.com/Derfuu/Derfuu_ComfyUI_ModdedNodes.git"
    "https://github.com/shadowcz007/comfyui-mixlab-nodes.git"
    "https://github.com/kijai/ComfyUI-Florence2.git"
    "https://github.com/Stability-AI/stability-ComfyUI-nodes.git"
    "https://github.com/kadirnar/ComfyUI-YOLO.git"
    "https://github.com/un-seen/comfyui-tensorops.git"
)

for repo in "${repos[@]}"; do
    clone_or_pull "$repo"
done

# Download files for /data/models
[[ -f /docker/models.txt ]] && aria2c -x 10 --disable-ipv6 --input-file /docker/models.txt --dir /data_simple/models --continue

echo "All download processes completed."
