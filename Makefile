# ComfyUI Workspace Makefile
# Uses UV for fast Python package management

.PHONY: help setup install sync download-models download-nodes download-all run run-cpu update clean reset

# Configuration
PYTHON_VERSION := 3.12
COMFY_REPO := https://github.com/comfyanonymous/ComfyUI.git
COMFY_DIR := comfy
DATA_DIR := data
PORT := 7860

# Python via UV (ensures correct version and dependencies)
PYTHON := uv run python

# Colors for output
GREEN := \033[0;32m
YELLOW := \033[0;33m
RED := \033[0;31m
NC := \033[0m # No Color

help: ## Show this help message
	@echo "ComfyUI Workspace - UV + Makefile Setup"
	@echo ""
	@echo "Usage: make <target>"
	@echo ""
	@echo "Targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-20s$(NC) %s\n", $$1, $$2}'

# ============================================================================
# SETUP & INSTALLATION
# ============================================================================

check-uv: ## Check if UV is installed
	@if command -v uv >/dev/null 2>&1; then \
		echo "$(GREEN)✓ UV is installed:$(NC) $$(uv --version)"; \
	else \
		echo "$(RED)✗ UV is not installed. Installing...$(NC)"; \
		curl -LsSf https://astral.sh/uv/install.sh | sh; \
		echo "$(YELLOW)Please restart your shell or run: source ~/.bashrc$(NC)"; \
	fi

check-aria2: ## Check if aria2c is installed
	@if command -v aria2c >/dev/null 2>&1; then \
		echo "$(GREEN)✓ aria2c is installed:$(NC) $$(aria2c --version | head -1)"; \
	else \
		echo "$(RED)✗ aria2c is not installed.$(NC)"; \
		echo "Install with:"; \
		echo "  macOS: brew install aria2"; \
		echo "  Ubuntu: sudo apt install aria2"; \
		echo "  Fedora: sudo dnf install aria2"; \
		exit 1; \
	fi

check-deps: check-uv check-aria2 ## Check all dependencies

detect-gpu: ## Detect GPU and show recommended PyTorch
	@$(PYTHON) setup/detect_gpu.py

setup: check-uv ## Initial setup: create venv, clone ComfyUI, install deps
	@echo "$(GREEN)Setting up ComfyUI workspace...$(NC)"
	
	@# Create data directories
	@mkdir -p $(DATA_DIR)/{config,workflows,input,output}
	@mkdir -p $(DATA_DIR)/models/{checkpoints,clip,clip_vision,configs,controlnet,controlnet/flux}
	@mkdir -p $(DATA_DIR)/models/{diffusers,diffusion_models,embeddings,gligen,hypernetworks}
	@mkdir -p $(DATA_DIR)/models/{loras,photomaker,style_models,unet,upscale_models,vae,vae_approx}
	@mkdir -p $(DATA_DIR)/models/{sam2,mmdets,onnx,liveportrait}
	@mkdir -p $(DATA_DIR)/models/ultralytics/{bbox,segm}
	@mkdir -p $(DATA_DIR)/custom_nodes
	
	@# Clone ComfyUI if not exists
	@if [ ! -d "$(COMFY_DIR)" ]; then \
		echo "$(GREEN)Cloning ComfyUI...$(NC)"; \
		git clone --depth=1 $(COMFY_REPO) $(COMFY_DIR); \
	else \
		echo "$(YELLOW)ComfyUI already exists, pulling latest...$(NC)"; \
		cd $(COMFY_DIR) && git pull --ff-only || true; \
	fi
	
	@# Create virtual environment and install dependencies
	@echo "$(GREEN)Creating virtual environment with UV...$(NC)"
	@uv venv --python $(PYTHON_VERSION)
	
	@# Install base dependencies first
	@echo "$(GREEN)Installing base dependencies...$(NC)"
	@uv pip install pyyaml structlog
	
	@# Detect GPU and install appropriate PyTorch
	@echo "$(GREEN)Detecting GPU and installing PyTorch...$(NC)"
	@$(PYTHON) setup/detect_gpu.py --install
	
	@# Install remaining dependencies
	@echo "$(GREEN)Installing ComfyUI dependencies...$(NC)"
	@uv pip install -r $(COMFY_DIR)/requirements.txt
	@uv pip install .
	
	@# Copy extra_model_paths.yaml to ComfyUI
	@cp extra_model_paths.yaml $(COMFY_DIR)/extra_model_paths.yaml
	
	@echo ""
	@echo "$(GREEN)Setup complete!$(NC)"
	@echo "Next steps:"
	@echo "  1. make download-nodes  - Download custom nodes"
	@echo "  2. make download-models - Download AI models"
	@echo "  3. make run             - Start ComfyUI"
	@echo ""
	@echo "$(YELLOW)If you have GPU issues, try:$(NC)"
	@echo "  make run-fp32     - Force 32-bit precision"
	@echo "  make run-lowvram  - Low VRAM mode"
	@echo "  make run-cpu      - CPU only mode"

install: check-uv ## Install/reinstall Python dependencies
	@echo "$(GREEN)Installing dependencies...$(NC)"
	@uv pip install -r $(COMFY_DIR)/requirements.txt
	@uv pip install .
	@echo "$(GREEN)Dependencies installed!$(NC)"

install-pytorch: ## Auto-detect GPU and install correct PyTorch
	@echo "$(GREEN)Installing PyTorch for your GPU...$(NC)"
	@$(PYTHON) setup/detect_gpu.py --install

install-pytorch-cuda124: ## Install PyTorch with CUDA 12.4
	@echo "$(GREEN)Installing PyTorch with CUDA 12.4...$(NC)"
	@uv pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu124

install-pytorch-cuda118: ## Install PyTorch with CUDA 11.8
	@echo "$(GREEN)Installing PyTorch with CUDA 11.8...$(NC)"
	@uv pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118

install-pytorch-cpu: ## Install PyTorch CPU-only
	@echo "$(GREEN)Installing PyTorch (CPU only)...$(NC)"
	@uv pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu

install-cuda: install ## Install with CUDA support (cupy)
	@echo "$(GREEN)Installing CUDA dependencies...$(NC)"
	@uv pip install ".[cuda]"

sync: check-uv ## Sync dependencies (fast update)
	@uv pip sync

# ============================================================================
# DOWNLOAD MODELS & NODES
# ============================================================================

download-nodes: ## Download/update custom nodes
	@$(PYTHON) setup/download_nodes.py $(DATA_DIR)/custom_nodes setup/nodes.yaml

download-models: check-aria2 ## Download AI models (checkpoints, VAE, etc.)
	@$(PYTHON) setup/download_models.py $(DATA_DIR)/models setup/models.yaml

download-all: download-nodes download-models ## Download everything (nodes + models)
	@echo "$(GREEN)All downloads complete!$(NC)"

# ============================================================================
# ADD MODELS & NODES
# ============================================================================

add-model: ## Add a model to download list (interactive)
	@$(PYTHON) setup/add_model.py

add-node: ## Add a custom node to download list (interactive)
	@$(PYTHON) setup/add_node.py

list-models: ## List all models in download config
	@echo "$(GREEN)Models in setup/models.yaml:$(NC)"
	@$(PYTHON) -c "import yaml; config=yaml.safe_load(open('setup/models.yaml')); [print(f'  {folder}/{m[\"name\"]}') for folder, models in config.items() for m in models if isinstance(m, dict)]"

list-nodes: ## List all custom nodes in download config
	@echo "$(GREEN)Custom nodes in setup/nodes.yaml:$(NC)"
	@$(PYTHON) -c "import yaml; config=yaml.safe_load(open('setup/nodes.yaml')); [print(f'  [{cat}] {url.split(\"/\")[-1]}') for cat, urls in config.items() for url in urls if isinstance(urls, list)]"

# ============================================================================
# RUNNING COMFYUI
# ============================================================================

run: ## Start ComfyUI (GPU, auto-detect)
	@echo "$(GREEN)Starting ComfyUI on port $(PORT)...$(NC)"
	@cd $(COMFY_DIR) && ../.venv/bin/python main.py \
		--listen 0.0.0.0 \
		--port $(PORT) \
		--extra-model-paths-config extra_model_paths.yaml

run-cpu: ## Start ComfyUI (CPU only)
	@echo "$(GREEN)Starting ComfyUI on CPU...$(NC)"
	@cd $(COMFY_DIR) && ../.venv/bin/python main.py \
		--listen 0.0.0.0 \
		--port $(PORT) \
		--cpu \
		--extra-model-paths-config extra_model_paths.yaml

run-fp32: ## Start ComfyUI with FP32 (fixes vGPU/compatibility issues)
	@echo "$(GREEN)Starting ComfyUI with FP32 precision...$(NC)"
	@echo "$(YELLOW)Using 32-bit precision for better GPU compatibility$(NC)"
	@cd $(COMFY_DIR) && ../.venv/bin/python main.py \
		--listen 0.0.0.0 \
		--port $(PORT) \
		--force-fp32 \
		--extra-model-paths-config extra_model_paths.yaml

run-lowvram: ## Start ComfyUI with low VRAM mode
	@echo "$(GREEN)Starting ComfyUI in low VRAM mode...$(NC)"
	@cd $(COMFY_DIR) && ../.venv/bin/python main.py \
		--listen 0.0.0.0 \
		--port $(PORT) \
		--lowvram \
		--extra-model-paths-config extra_model_paths.yaml

run-lowvram-fp32: ## Start with low VRAM + FP32 (safest for problematic GPUs)
	@echo "$(GREEN)Starting ComfyUI in low VRAM + FP32 mode...$(NC)"
	@echo "$(YELLOW)Safest mode for GPUs with compatibility issues$(NC)"
	@cd $(COMFY_DIR) && ../.venv/bin/python main.py \
		--listen 0.0.0.0 \
		--port $(PORT) \
		--lowvram \
		--force-fp32 \
		--disable-cuda-malloc \
		--extra-model-paths-config extra_model_paths.yaml

run-highvram: ## Start ComfyUI with high VRAM mode (faster)
	@echo "$(GREEN)Starting ComfyUI in high VRAM mode...$(NC)"
	@cd $(COMFY_DIR) && ../.venv/bin/python main.py \
		--listen 0.0.0.0 \
		--port $(PORT) \
		--highvram \
		--extra-model-paths-config extra_model_paths.yaml

run-debug: ## Start ComfyUI with debug options
	@echo "$(GREEN)Starting ComfyUI in debug mode...$(NC)"
	@cd $(COMFY_DIR) && CUDA_LAUNCH_BLOCKING=1 ../.venv/bin/python main.py \
		--listen 0.0.0.0 \
		--port $(PORT) \
		--force-fp32 \
		--verbose \
		--extra-model-paths-config extra_model_paths.yaml

# ============================================================================
# MAINTENANCE
# ============================================================================

update: ## Update ComfyUI and custom nodes
	@echo "$(GREEN)Updating ComfyUI...$(NC)"
	@cd $(COMFY_DIR) && git pull --ff-only
	
	@echo "$(GREEN)Updating custom nodes...$(NC)"
	@$(PYTHON) setup/download_nodes.py $(DATA_DIR)/custom_nodes
	
	@echo "$(GREEN)Updating dependencies...$(NC)"
	@uv pip install -r $(COMFY_DIR)/requirements.txt
	@uv pip install .
	
	@echo "$(GREEN)Update complete!$(NC)"

update-nodes: ## Update only custom nodes
	@echo "$(GREEN)Updating custom nodes...$(NC)"
	@$(PYTHON) setup/download_nodes.py $(DATA_DIR)/custom_nodes

install-node-deps: ## Install dependencies for all custom nodes
	@echo "$(GREEN)Installing custom node dependencies...$(NC)"
	@for dir in $(DATA_DIR)/custom_nodes/*/; do \
		if [ -f "$$dir/requirements.txt" ]; then \
			echo "Installing deps for $$(basename $$dir)..."; \
			uv pip install -r "$$dir/requirements.txt" || true; \
		fi \
	done
	@echo "$(GREEN)Custom node dependencies installed!$(NC)"

clean: ## Clean cache and temporary files
	@echo "$(YELLOW)Cleaning cache files...$(NC)"
	@find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	@find . -type f -name "*.pyc" -delete 2>/dev/null || true
	@rm -rf .pytest_cache .ruff_cache 2>/dev/null || true
	@echo "$(GREEN)Clean complete!$(NC)"

reset: ## Full reset (remove venv and ComfyUI, keep data)
	@echo "$(RED)This will remove the virtual environment and ComfyUI installation.$(NC)"
	@echo "$(YELLOW)Your models and outputs in $(DATA_DIR)/ will be preserved.$(NC)"
	@read -p "Are you sure? [y/N] " confirm && [ "$$confirm" = "y" ] || exit 1
	@rm -rf .venv $(COMFY_DIR)
	@echo "$(GREEN)Reset complete. Run 'make setup' to reinstall.$(NC)"

# ============================================================================
# INFO & DEBUGGING
# ============================================================================

info: ## Show environment information
	@echo "$(GREEN)Environment Information$(NC)"
	@echo "========================"
	@echo "Python: $$(uv run python --version 2>/dev/null || echo 'Not installed')"
	@echo "UV: $$(uv --version 2>/dev/null || echo 'Not installed')"
	@echo "ComfyUI: $(COMFY_DIR)"
	@echo "Data: $(DATA_DIR)"
	@echo "Port: $(PORT)"
	@echo ""
	@echo "Directories:"
	@echo "  Models: $(DATA_DIR)/models/"
	@echo "  Custom Nodes: $(DATA_DIR)/custom_nodes/"
	@echo "  Output: $(DATA_DIR)/output/"
	@echo "  Input: $(DATA_DIR)/input/"

gpu-info: ## Show GPU information
	@echo "$(GREEN)GPU Information$(NC)"
	@uv run python -c "import torch; print(f'CUDA available: {torch.cuda.is_available()}'); print(f'Device count: {torch.cuda.device_count()}'); [print(f'  {i}: {torch.cuda.get_device_name(i)}') for i in range(torch.cuda.device_count())] if torch.cuda.is_available() else None" 2>/dev/null || echo "PyTorch not installed or no GPU available"
