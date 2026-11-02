# ComfyUI Workspace

A modern ComfyUI setup using **UV** for fast Python package management and **Make** for automation. Includes pre-configured models, custom nodes, and workflows for AI image generation.

## Features

- **Fast setup** with UV (10-100x faster than pip)
- **60+ custom nodes** pre-configured
- **Curated model collection** (checkpoints, VAEs, ControlNet, upscalers, etc.)
- **Simple commands** via Makefile
- **GPU support** with multiple VRAM modes

## Prerequisites

- **Python 3.12+** (3.13 recommended) 
- **NVIDIA GPU** with CUDA support (optional, CPU mode available)
- **aria2** for fast model downloads

### Install Prerequisites

```bash
# macOS
brew install aria2

# Ubuntu/Debian
sudo apt install aria2

# Fedora
sudo dnf install aria2
```

UV will be automatically installed when you run `make setup`.

## Quick Start

```bash
# 1. Initial setup (creates venv, clones ComfyUI, installs deps)
make setup

# 2. Download custom nodes
make download-nodes

# 3. Download AI models (this takes a while, ~50GB+)
make download-models

# 4. Start ComfyUI
make run
```

Then open http://localhost:7860 in your browser.

## Available Commands

Run `make help` to see all available commands:

| Command | Description |
|---------|-------------|
| `make setup` | Initial setup (auto-detects GPU, installs PyTorch) |
| `make detect-gpu` | Detect GPU and show recommended PyTorch |
| `make check-pytorch` | Check current PyTorch installation and GPU |
| `make install-pytorch` | Auto-install PyTorch for your GPU |
| `make install-pytorch-nightly` | Install PyTorch nightly (newest CUDA support) |
| `make install-pytorch-cu130` | Install PyTorch with CUDA 13.0 |
| `make install-pytorch-cu128` | Install PyTorch with CUDA 12.8 |
| `make install-pytorch-cu126` | Install PyTorch with CUDA 12.6 |
| `make install-pytorch-cu124` | Install PyTorch with CUDA 12.4 |
| `make install-pytorch-cu118` | Install PyTorch with CUDA 11.8 |
| `make install-pytorch-cpu` | Install PyTorch CPU-only |
| `make download-nodes` | Download/update custom nodes |
| `make download-models` | Download AI models |
| `make download-all` | Download everything (nodes + models) |
| `make add-model` | Add a new model (interactive) |
| `make add-node` | Add a new custom node (interactive) |
| `make run` | Start ComfyUI (GPU, auto-detect) |
| `make run-cpu` | Start ComfyUI (CPU only) |
| `make run-fp32` | Start with FP32 (fixes vGPU issues) |
| `make run-lowvram` | Start with low VRAM mode |
| `make run-lowvram-fp32` | Safest mode for problematic GPUs |
| `make run-highvram` | Start with high VRAM mode (faster) |
| `make run-debug` | Start with debug options |
| `make update` | Update ComfyUI and custom nodes |
| `make install-node-deps` | Install custom node dependencies |
| `make clean` | Clean cache files |
| `make reset` | Full reset (keeps data) |
| `make gpu-info` | Show GPU information |

## Directory Structure

```
.
├── Makefile                    # Build automation
├── README.MD                   # This file
├── pyproject.toml              # Python dependencies
├── extra_model_paths.yaml      # ComfyUI model paths config
├── setup/                      # Scripts and config files
│   ├── models.yaml             # Model download list (YAML)
│   ├── nodes.yaml              # Custom nodes list (YAML)
│   ├── add_model.py            # Script to add models
│   ├── add_node.py             # Script to add nodes
│   ├── download_models.py      # Script to download models
│   └── download_nodes.py       # Script to download nodes
├── comfy/                      # ComfyUI installation (created by setup)
└── data/                       # All persistent data (created by setup)
    ├── custom_nodes/           # Custom node installations
    ├── input/                  # Input images
    ├── output/                 # Generated images
    ├── workflows/              # Saved workflows
    └── models/                 # AI models
        ├── checkpoints/        # Main SD models
        ├── loras/              # LoRA models
        ├── vae/                # VAE models
        ├── controlnet/         # ControlNet models
        ├── upscale_models/     # Upscaling models
        └── ...                 # Other model folders
```

## Included Models

### Checkpoints
- Stable Diffusion 1.5
- DreamShaper 8
- SDXL Turbo
- Playground v2.5
- RealVisXL V4.0
- FLUX.1 Depth-dev

### Upscalers
- RealESRGAN (2x, 4x, 8x)
- AnimeSharp 4x
- UltraSharp 4x
- SUPIR

### ControlNet
- Full SD 1.5 v1.1 collection (depth, canny, openpose, etc.)
- SDXL ControlNet Union
- FLUX ControlNet Union
- Control-LoRA variants

### Other
- VAE models (SD, SDXL, FLUX)
- CLIP text encoders
- SAM2 segmentation models
- YOLO face/person detection
- LoRAs and embeddings

## Custom Nodes

60+ custom nodes are included for:
- **Workflow Management**: ComfyUI Manager, Impact Pack
- **Image Processing**: Upscaling, face detection, segmentation
- **ControlNet**: Depth, pose, canny preprocessing
- **Video**: Frame interpolation, video export
- **Utilities**: Logic nodes, prompt styling, image saving

See `setup/nodes.yaml` for the full list.

## LipSync Workflow (LTX-2.3 Dub-It)

`LipSync - LTX-2.3 Dub-It.json` makes an actor in an existing clip say a new line: new lip movement and new audio, with the voice cloned from the clip. The new line is written in the prompt. Guidance notes for each step are inside the workflow.

Its models (~50GB) and nodes are kept out of the default downloads:

```bash
# 1. Accept the license at https://huggingface.co/Lightricks/LTX-2.3-22b-IC-LoRA-DubIt
# 2. Create a read token at https://huggingface.co/settings/tokens
export HF_TOKEN=hf_...
make lipsync-setup     # updates ComfyUI core, downloads nodes + models, installs deps, adds the workflow
make run               # leave running, open http://localhost:7860
make lipsync-check     # in a second terminal: GPU, nodes, models, and what the server sees
```

### Testing from the terminal

`make lipsync-test` queues the workflow through the ComfyUI API, waits, and prints the output path. It needs the API version of the workflow once: in ComfyUI open the LipSync workflow, then **Workflow → Export (API)**, and save it in the repo root as `LipSync - LTX-2.3 Dub-It (API).json`.

```bash
make lipsync-test CLIP=~/clips/actor.mp4 \
  PROMPT='A man at a desk, looking at the camera, speaking in English saying: "We ship on Friday, no excuses."'
```

| Option | Default | Meaning |
|---|---|---|
| `CLIP` | required | Video of one person speaking, face visible |
| `PROMPT` | the workflow's | Shot description + `speaking in <language> saying: "<new line>"` |
| `TRIM` | `5` | Keep the first N seconds (`0` = whole clip) |
| `PRESET` | `32gb` | Size preset: `32gb` (960×544 → 1920×1088), `24gb` (768×448 → 1536×896), `preview` (640×352 → 1280×704) |
| `SEED` | the workflow's | Change for another take |

Requires an NVIDIA GPU, 32GB+ VRAM recommended. See `setup/models-lipsync.yaml` and `setup/nodes-lipsync.yaml`.

### Using it from another computer

`make run` listens on the network, so the GPU machine can stay headless:

- **Browser:** open `http://<gpu-machine-ip>:7860`. LoadVideo's upload button sends a clip from your computer; right-click the output video → Save to download it.
- **Terminal:** add `COMFY_URL` to the check and test targets. The clip is uploaded, and results are saved to `~/Downloads` (change with `OUT=`). Only `uv` is needed on that computer, no `make setup`.

```bash
make lipsync-check COMFY_URL=http://192.168.1.50:7860
make lipsync-test  COMFY_URL=http://192.168.1.50:7860 CLIP=~/clips/actor.mp4 PROMPT='...'
```

ComfyUI has no login: anyone who can reach port 7860 can use it. Keep it on your home network, or use [Tailscale](https://tailscale.com) or an SSH tunnel (`ssh -L 7860:localhost:7860 you@gpu-machine`, then `http://localhost:7860`) from outside.

## Adding Custom Models

### Interactive (Recommended)
```bash
make add-model
```

This will prompt you for:
1. **Model URL** - Direct download link
2. **Target folder** - Where to save (checkpoints, loras, vae, etc.)
3. **New filename** - Optional, leave empty to keep original name

### Manual
Edit `setup/models.yaml` directly:

```yaml
checkpoints:
  - url: https://example.com/model.safetensors
    name: my_model.safetensors
```

Then run `make download-models`.

### Via Script
```bash
# Keep original filename
uv run python setup/add_model.py "https://example.com/model.safetensors" checkpoints

# With custom filename
uv run python setup/add_model.py "https://example.com/model.safetensors" loras "my_lora.safetensors"
```

## Adding Custom Nodes

### Interactive (Recommended)
```bash
make add-node
```

This will prompt you for the GitHub repository URL and category.

### Manual
Edit `setup/nodes.yaml` and add the GitHub URL:

```yaml
utilities:
  - https://github.com/username/ComfyUI-NodeName
```

Then run `make download-nodes`.

### Via Script
```bash
python setup/add_node.py "https://github.com/username/ComfyUI-NodeName"
```

## Troubleshooting

### CUDA Errors / GPU Issues
```bash
# Check current PyTorch installation and GPU detection
make check-pytorch

# Detect your GPU and show recommended PyTorch version
make detect-gpu

# Try FP32 mode (fixes many vGPU and compatibility issues)
make run-fp32

# Safest mode for problematic GPUs
make run-lowvram-fp32

# Debug mode (shows detailed CUDA errors)
make run-debug

# Run in CPU mode as fallback
make run-cpu
```

### Wrong PyTorch Version
```bash
# Check what's currently installed
make check-pytorch

# Auto-detect and reinstall correct PyTorch
make install-pytorch

# Or manually install specific CUDA version
make install-pytorch-cu130    # For CUDA 13.x drivers
make install-pytorch-cu128    # For CUDA 12.8+ drivers
make install-pytorch-cu126    # For CUDA 12.6+ drivers  
make install-pytorch-cu124    # For CUDA 12.x drivers
make install-pytorch-cu118    # For CUDA 11.x drivers
make install-pytorch-cpu      # CPU only
```

### Out of VRAM
```bash
# Use low VRAM mode
make run-lowvram
```

### Custom Node Errors
```bash
# Install missing dependencies for custom nodes
make install-node-deps
```

### Reset Everything
```bash
# Full reset (keeps models and outputs)
make reset
make setup
```

## Migration from Docker

If you previously used the Docker setup:

1. Your models in `data/models/` are compatible - no re-download needed
2. Copy any custom nodes from `data/custom_nodes/` 
3. Copy your outputs from `data/output/`
4. Run `make setup` to create the new environment

## License

This project provides configuration and automation for ComfyUI. See the respective licenses for:
- [ComfyUI](https://github.com/comfyanonymous/ComfyUI)
- Individual models and custom nodes
