#!/usr/bin/env bash

set -Eeuo pipefail

# Create necessary directories
mkdir -vp /data_simple/{config,workflows,input,custom_nodes,output,models/{checkpoints,clip,clip_vision,configs,diffusers,diffusion_models,embeddings,gligen,hypernetworks,loras,photomaker,style_models,unet,upscale_models,vae,vae_approx,sam2,mmdets,onnx,liveportrait,ultralytics}}

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
)

for repo in "${repos[@]}"; do
    clone_or_pull "$repo"
done

# Download files for /data/models
[[ -f /docker/models.txt ]] && aria2c -x 10 --disable-ipv6 --input-file /docker/models.txt --dir /data_simple/models --continue

echo "All download processes completed."
