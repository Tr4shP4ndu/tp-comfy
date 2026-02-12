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
