#!/usr/bin/env bash

set -Eeuo pipefail

# Create necessary directories
mkdir -vp /data/{config,workspaces,input,custom_nodes,output,models/{checkpoints,clip,clip_vision,configs,diffusers,diffusion_models,embeddings,gligen,hypernetworks,loras,photomaker,style_models,unet,upscale_models,vae,vae_approx,sam2,animatediff_models,animatediff_motion_lora,mmdets,onnx,liveportrait}}

function clone_or_pull () {
    if [[ $1 =~ ^(.*[/:])(.*)(\.git)$ ]] || [[ $1 =~ ^(http.*\/)(.*)$ ]]; then
        echo "${BASH_REMATCH[2]}" ;
        set +e ;
            git clone --depth=1 --no-tags --recurse-submodules --shallow-submodules "$1" \
                || git -C "${BASH_REMATCH[2]}" pull --ff-only ;
        set -e ;
    else
        echo "[ERROR] Invalid URL: $1" ;
        return 1 ;
    fi ;
}
cd /data/custom_nodes

echo "########################################"
echo "[INFO] Downloading Custom Nodes..."
echo "########################################"

# Workspace
clone_or_pull https://github.com/ltdrdata/ComfyUI-Manager.git
clone_or_pull https://github.com/11cafe/comfyui-workspace-manager.git
clone_or_pull https://github.com/AIGODLIKE/AIGODLIKE-ComfyUI-Translation.git
clone_or_pull https://github.com/crystian/ComfyUI-Crystools.git
clone_or_pull https://github.com/crystian/ComfyUI-Crystools-save.git
clone_or_pull https://github.com/giriss/comfy-image-saver.git
clone_or_pull https://github.com/griptape-ai/ComfyUI-Griptape.git

# General
clone_or_pull https://github.com/bash-j/mikey_nodes.git
clone_or_pull https://github.com/chrisgoringe/cg-use-everywhere.git
clone_or_pull https://github.com/cubiq/ComfyUI_essentials.git
clone_or_pull https://github.com/jags111/efficiency-nodes-comfyui.git
clone_or_pull https://github.com/kijai/ComfyUI-KJNodes.git
clone_or_pull https://github.com/pythongosssss/ComfyUI-Custom-Scripts.git
# clone_or_pull https://github.com/rgthree/rgthree-comfy.git
clone_or_pull https://github.com/shiimizu/ComfyUI_smZNodes.git
clone_or_pull https://github.com/GTSuya-Studio/ComfyUI-Gtsuya-Nodes.git
clone_or_pull https://github.com/daxcay/ComfyUI-JDCN.git
# clone_or_pull https://github.com/filliptm/ComfyUI_Fill-Nodes.git
clone_or_pull https://github.com/aria1th/ComfyUI-LogicUtils.git
clone_or_pull https://github.com/kijai/ComfyUI-depth-fm.git
clone_or_pull https://github.com/kijai/ComfyUI-Geowizard.git
clone_or_pull https://github.com/kijai/ComfyUI-Marigold.git
clone_or_pull https://github.com/picturesonpictures/comfy_PoP.git
clone_or_pull https://github.com/Derfuu/Derfuu_ComfyUI_ModdedNodes.git
clone_or_pull https://github.com/sipherxyz/comfyui-art-venture.git

# Control
clone_or_pull https://github.com/cubiq/ComfyUI_InstantID.git
clone_or_pull https://github.com/cubiq/ComfyUI_IPAdapter_plus.git
clone_or_pull https://github.com/Fannovel16/comfyui_controlnet_aux.git
clone_or_pull https://github.com/florestefano1975/comfyui-portrait-master.git
# clone_or_pull https://github.com/Gourieff/comfyui-reactor-node.git
clone_or_pull https://github.com/huchenlei/ComfyUI-layerdiffuse.git
# clone_or_pull https://github.com/Kosinkadink/ComfyUI-Advanced-ControlNet.git
# clone_or_pull https://github.com/ltdrdata/ComfyUI-Impact-Pack.git
clone_or_pull https://github.com/ltdrdata/ComfyUI-Inspire-Pack.git
clone_or_pull https://github.com/mcmonkeyprojects/sd-dynamic-thresholding.git
clone_or_pull https://github.com/storyicon/comfyui_segment_anything.git
clone_or_pull https://github.com/twri/sdxl_prompt_styler.git
clone_or_pull https://github.com/KoreTeknology/ComfyUI-Universal-Styler.git
clone_or_pull https://github.com/kijai/ComfyUI-Florence2.git
# clone_or_pull https://github.com/un-seen/comfyui-tensorops.git
# clone_or_pull https://github.com/PowerHouseMan/ComfyUI-AdvancedLivePortrait.git
clone_or_pull https://github.com/kijai/ComfyUI-LivePortraitKJ.git

# Video
clone_or_pull https://github.com/Fannovel16/ComfyUI-Frame-Interpolation.git
clone_or_pull https://github.com/FizzleDorf/ComfyUI_FizzNodes.git
clone_or_pull https://github.com/Kosinkadink/ComfyUI-AnimateDiff-Evolved.git
clone_or_pull https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git
clone_or_pull https://github.com/melMass/comfy_mtb.git
clone_or_pull https://github.com/MrForExample/ComfyUI-AnimateAnyone-Evolved.git

# More
clone_or_pull https://github.com/cubiq/ComfyUI_FaceAnalysis.git
clone_or_pull https://github.com/pythongosssss/ComfyUI-WD14-Tagger.git
clone_or_pull https://github.com/SLAPaper/ComfyUI-Image-Selector.git
clone_or_pull https://github.com/kijai/ComfyUI-segment-anything-2.git

# WAS NS' deps were not fully installed, but it can still run, and have most features enabled
# clone_or_pull https://github.com/WASasquatch/was-node-suite-comfyui.git

# Download files for /data/models
[[ -f /docker/models.txt ]] && aria2c -x 10 --disable-ipv6 --input-file /docker/models.txt --dir /data/models --continue

echo "All download processes completed."
