# ComfyUI Workspace Makefile
# Uses UV for fast Python package management

.PHONY: help setup install sync download-models download-nodes download-all run run-cpu update clean reset

# Configuration
PYTHON_VERSION := 3.12
COMFY_REPO := https://github.com/comfyanonymous/ComfyUI.git
COMFY_DIR := comfy
DATA_DIR := data
PORT := 7860

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
	
	@echo "$(GREEN)Installing dependencies...$(NC)"
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

install: check-uv ## Install/reinstall Python dependencies
	@echo "$(GREEN)Installing dependencies...$(NC)"
	@uv pip install -r $(COMFY_DIR)/requirements.txt
	@uv pip install .
	@echo "$(GREEN)Dependencies installed!$(NC)"

install-cuda: install ## Install with CUDA support (cupy)
	@echo "$(GREEN)Installing CUDA dependencies...$(NC)"
	@uv pip install ".[cuda]"

sync: check-uv ## Sync dependencies (fast update)
	@uv pip sync

# ============================================================================
# DOWNLOAD MODELS & NODES
# ============================================================================

download-nodes: ## Download/update custom nodes
	@echo "$(GREEN)Downloading custom nodes...$(NC)"
	@bash scripts/download_nodes.sh $(DATA_DIR)/custom_nodes config/nodes.txt

download-models: check-aria2 ## Download AI models (checkpoints, VAE, etc.)
	@echo "$(GREEN)Downloading models...$(NC)"
	@aria2c -x 10 --disable-ipv6 --input-file config/models.txt --dir $(DATA_DIR)/models --continue
	@echo "$(GREEN)Models downloaded!$(NC)"

download-all: download-nodes download-models ## Download everything (nodes + models)
	@echo "$(GREEN)All downloads complete!$(NC)"

# ============================================================================
# ADD MODELS & NODES
# ============================================================================

add-model: ## Add a model to download list (interactive)
	@echo "$(GREEN)Add Model to Download List$(NC)"
	@echo "=========================="
	@echo ""
	@echo "┌─────────────────────────────────────────────────────────────────────────────┐"
	@echo "│ $(YELLOW)STEP 1: Model URL$(NC)                                                          │"
	@echo "│                                                                             │"
	@echo "│ Paste the direct download URL for the model file.                           │"
	@echo "│                                                                             │"
	@echo "│ $(YELLOW)Example input:$(NC)                                                              │"
	@echo "│ $(GREEN)https://huggingface.co/stabilityai/sdxl-turbo/resolve/main/model.safetensors$(NC) │"
	@echo "└─────────────────────────────────────────────────────────────────────────────┘"
	@echo ""
	@read -p "Model URL: " url; \
	echo ""; \
	echo "┌─────────────────────────────────────────────────────────────────────────────┐"; \
	echo "│ $(YELLOW)STEP 2: Target Folder$(NC)                                                       │"; \
	echo "│                                                                             │"; \
	echo "│ Where should this model be saved?                                           │"; \
	echo "│                                                                             │"; \
	echo "│ $(YELLOW)Options:$(NC)                                                                     │"; \
	echo "│   checkpoints    - Main models (SD 1.5, SDXL, FLUX, etc.)                   │"; \
	echo "│   loras          - LoRA/LyCORIS models                                      │"; \
	echo "│   vae            - VAE models                                               │"; \
	echo "│   controlnet     - ControlNet models                                        │"; \
	echo "│   upscale_models - Upscalers (ESRGAN, etc.)                                 │"; \
	echo "│   embeddings     - Textual inversions / embeddings                          │"; \
	echo "│   clip           - CLIP text encoders                                       │"; \
	echo "│   unet           - UNET models (for FLUX)                                   │"; \
	echo "│                                                                             │"; \
	echo "│ $(YELLOW)Example input:$(NC)                                                               │"; \
	echo "│ $(GREEN)checkpoints$(NC)                                                                   │"; \
	echo "└─────────────────────────────────────────────────────────────────────────────┘"; \
	echo ""; \
	read -p "Target folder: " folder; \
	echo ""; \
	echo "┌─────────────────────────────────────────────────────────────────────────────┐"; \
	echo "│ $(YELLOW)STEP 3: Filename (optional)$(NC)                                                  │"; \
	echo "│                                                                             │"; \
	echo "│ Press ENTER to keep the original filename from the URL.                     │"; \
	echo "│ Or type a new name if you want to rename it.                                │"; \
	echo "│                                                                             │"; \
	echo "│ $(YELLOW)Example input:$(NC)                                                               │"; \
	echo "│ $(GREEN)my_custom_model.safetensors$(NC)   (or just press ENTER)                           │"; \
	echo "└─────────────────────────────────────────────────────────────────────────────┘"; \
	echo ""; \
	read -p "New filename (press ENTER to skip): " filename; \
	bash scripts/add_model.sh "$$url" "$$folder" "$$filename"

add-node: ## Add a custom node to download list (interactive)
	@echo "$(GREEN)Add Custom Node$(NC)"
	@echo "==============="
	@echo ""
	@echo "┌─────────────────────────────────────────────────────────────────────────────┐"
	@echo "│ $(YELLOW)GitHub Repository URL$(NC)                                                       │"
	@echo "│                                                                             │"
	@echo "│ Paste the GitHub URL for the custom node repository.                        │"
	@echo "│ The .git extension is optional.                                             │"
	@echo "│                                                                             │"
	@echo "│ $(YELLOW)Example inputs:$(NC)                                                             │"
	@echo "│ $(GREEN)https://github.com/ltdrdata/ComfyUI-Manager$(NC)                                  │"
	@echo "│ $(GREEN)https://github.com/cubiq/ComfyUI_essentials.git$(NC)                              │"
	@echo "│ $(GREEN)https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite$(NC)                      │"
	@echo "└─────────────────────────────────────────────────────────────────────────────┘"
	@echo ""
	@read -p "GitHub URL: " url; \
	bash scripts/add_node.sh "$$url"

list-models: ## List all models in download config
	@echo "$(GREEN)Models in config/models.txt:$(NC)"
	@grep "out=" config/models.txt | sed 's/.*out=/  /' | sort

list-nodes: ## List all custom nodes in download config
	@echo "$(GREEN)Custom nodes in config/nodes.txt:$(NC)"
	@grep -v "^#" config/nodes.txt | grep -v "^$$" | sed 's|.*/||' | sed 's|\.git||' | sort

# ============================================================================
# RUNNING COMFYUI
# ============================================================================

run: ## Start ComfyUI (GPU)
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

run-lowvram: ## Start ComfyUI with low VRAM mode
	@echo "$(GREEN)Starting ComfyUI in low VRAM mode...$(NC)"
	@cd $(COMFY_DIR) && ../.venv/bin/python main.py \
		--listen 0.0.0.0 \
		--port $(PORT) \
		--lowvram \
		--extra-model-paths-config extra_model_paths.yaml

run-highvram: ## Start ComfyUI with high VRAM mode (faster)
	@echo "$(GREEN)Starting ComfyUI in high VRAM mode...$(NC)"
	@cd $(COMFY_DIR) && ../.venv/bin/python main.py \
		--listen 0.0.0.0 \
		--port $(PORT) \
		--highvram \
		--extra-model-paths-config extra_model_paths.yaml

# ============================================================================
# MAINTENANCE
# ============================================================================

update: ## Update ComfyUI and custom nodes
	@echo "$(GREEN)Updating ComfyUI...$(NC)"
	@cd $(COMFY_DIR) && git pull --ff-only
	
	@echo "$(GREEN)Updating custom nodes...$(NC)"
	@bash scripts/download_nodes.sh $(DATA_DIR)/custom_nodes
	
	@echo "$(GREEN)Updating dependencies...$(NC)"
	@uv pip install -r $(COMFY_DIR)/requirements.txt
	@uv pip install .
	
	@echo "$(GREEN)Update complete!$(NC)"

update-nodes: ## Update only custom nodes
	@echo "$(GREEN)Updating custom nodes...$(NC)"
	@bash scripts/download_nodes.sh $(DATA_DIR)/custom_nodes

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
