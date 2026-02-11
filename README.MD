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
| `make setup` | Initial setup: venv, ComfyUI, dependencies |
| `make install` | Install/reinstall Python dependencies |
| `make install-cuda` | Install with CUDA support (cupy) |
| `make download-nodes` | Download/update custom nodes |
| `make download-models` | Download AI models |
| `make download-all` | Download everything (nodes + models) |
| `make add-model` | Add a new model to download list (interactive) |
| `make add-node` | Add a new custom node (interactive) |
| `make list-models` | List all models in config |
| `make list-nodes` | List all custom nodes in config |
| `make run` | Start ComfyUI (GPU) |
| `make run-cpu` | Start ComfyUI (CPU only) |
| `make run-lowvram` | Start with low VRAM mode |
| `make run-highvram` | Start with high VRAM mode (faster) |
| `make update` | Update ComfyUI and custom nodes |
| `make update-nodes` | Update only custom nodes |
| `make install-node-deps` | Install custom node dependencies |
| `make clean` | Clean cache files |
| `make reset` | Full reset (keeps data) |
| `make info` | Show environment info |
| `make gpu-info` | Show GPU information |

## Directory Structure

```
.
├── comfy/                  # ComfyUI installation (git clone)
├── data/                   # All persistent data
│   ├── config/            # Configuration files
│   ├── custom_nodes/      # Custom node installations
│   ├── input/             # Input images
│   ├── output/            # Generated images
│   ├── workflows/         # Saved workflows
│   └── models/            # AI models
│       ├── checkpoints/   # Main SD models
│       ├── clip/          # CLIP text encoders
│       ├── clip_vision/   # CLIP vision models
│       ├── controlnet/    # ControlNet models
│       ├── embeddings/    # Textual inversions
│       ├── loras/         # LoRA models
│       ├── unet/          # UNET models (FLUX)
│       ├── upscale_models/# Upscaling models
│       ├── vae/           # VAE models
│       └── ...
├── config/
│   └── models.txt         # Model download list
├── scripts/
│   └── download_nodes.sh  # Custom node download script
├── Makefile               # Build automation
├── pyproject.toml         # Python dependencies
└── extra_model_paths.yaml # ComfyUI model paths config
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

See `config/nodes.txt` for the full list.

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
Edit `config/models.txt` directly:

```
https://example.com/model.safetensors
  out=checkpoints/my_model.safetensors
```

Then run `make download-models`.

### Via Script
```bash
# Keep original filename
./scripts/add_model.sh "https://example.com/model.safetensors" checkpoints

# With custom filename
./scripts/add_model.sh "https://example.com/model.safetensors" loras "my_lora.safetensors"
```

## Adding Custom Nodes

### Interactive (Recommended)
```bash
make add-node
```

This will prompt you for the GitHub repository URL.

### Manual
Edit `config/nodes.txt` and add the GitHub URL:

```
https://github.com/username/ComfyUI-NodeName.git
```

Then run `make download-nodes`.

### Via Script
```bash
./scripts/add_node.sh "https://github.com/username/ComfyUI-NodeName"
```

## Troubleshooting

### CUDA Not Available
```bash
# Check GPU status
make gpu-info

# Run in CPU mode
make run-cpu
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
