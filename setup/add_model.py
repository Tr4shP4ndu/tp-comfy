#!/usr/bin/env python3
"""
Add a model to the download list
Usage: 
  python add_model.py                           # Interactive mode
  python add_model.py <url> <folder> [filename] # Direct mode
"""

import sys
from pathlib import Path
from urllib.parse import urlparse, unquote

import structlog
import yaml

# Configure structlog for console output
structlog.configure(
    processors=[
        structlog.stdlib.add_log_level,
        structlog.dev.ConsoleRenderer(colors=True),
    ],
    wrapper_class=structlog.make_filtering_bound_logger(0),
    context_class=dict,
    logger_factory=structlog.PrintLoggerFactory(),
)

LOGGER = structlog.get_logger()

# Valid model folders
VALID_FOLDERS = [
    "checkpoints",
    "clip",
    "clip_vision",
    "configs",
    "controlnet",
    "controlnet/flux",
    "diffusers",
    "diffusion_models",
    "embeddings",
    "gligen",
    "hypernetworks",
    "loras",
    "photomaker",
    "style_models",
    "unet",
    "upscale_models",
    "vae",
    "vae_approx",
    "sam2",
    "ultralytics/bbox",
    "ultralytics/segm",
    "mmdets",
    "onnx",
    "liveportrait",
]

CONFIG_FILE = Path("setup/models.yaml")


def extract_filename(url: str) -> str | None:
    """Extract filename from URL."""
    parsed = urlparse(url)
    path = unquote(parsed.path)
    filename = Path(path).name
    
    # Handle query parameters that might contain the real filename
    if not filename or filename in ["download", "resolve"] or filename.isdigit():
        return None
    
    # Remove query string from filename if present
    if "?" in filename:
        filename = filename.split("?")[0]
    
    return filename if filename else None


def print_box(lines: list[str]):
    """Print a box with the given lines."""
    width = 77
    print("┌" + "─" * width + "┐")
    for line in lines:
        # Strip ANSI codes for length calculation
        import re
        clean_line = re.sub(r'\033\[[0-9;]*m', '', line)
        padding = width - len(clean_line)
        print(f"│ {line}{' ' * (padding - 1)}│")
    print("└" + "─" * width + "┘")


def interactive_mode():
    """Run in interactive mode with prompts."""
    print("\n\033[0;32mAdd Model to Download List\033[0m")
    print("=" * 26)
    print()
    
    # Step 1: URL
    print_box([
        "\033[0;33mSTEP 1: Model URL\033[0m",
        "",
        "Paste the direct download URL for the model file.",
        "",
        "\033[0;33mExample input:\033[0m",
        "\033[0;32mhttps://huggingface.co/stabilityai/sdxl-turbo/resolve/main/model.safetensors\033[0m",
    ])
    print()
    url = input("Model URL: ").strip()
    
    if not url:
        LOGGER.error("validation_failed", reason="URL is required")
        sys.exit(1)
    
    print()
    
    # Step 2: Folder
    print_box([
        "\033[0;33mSTEP 2: Target Folder\033[0m",
        "",
        "Where should this model be saved?",
        "",
        "\033[0;33mOptions:\033[0m",
        "  checkpoints    - Main models (SD 1.5, SDXL, FLUX, etc.)",
        "  loras          - LoRA/LyCORIS models",
        "  vae            - VAE models",
        "  controlnet     - ControlNet models",
        "  upscale_models - Upscalers (ESRGAN, etc.)",
        "  embeddings     - Textual inversions / embeddings",
        "  clip           - CLIP text encoders",
        "  unet           - UNET models (for FLUX)",
        "",
        "\033[0;33mExample input:\033[0m",
        "\033[0;32mcheckpoints\033[0m",
    ])
    print()
    folder = input("Target folder: ").strip()
    
    if not folder:
        LOGGER.error("validation_failed", reason="Folder is required")
        sys.exit(1)
    
    print()
    
    # Step 3: Filename
    print_box([
        "\033[0;33mSTEP 3: Filename (optional)\033[0m",
        "",
        "Press ENTER to keep the original filename from the URL.",
        "Or type a new name if you want to rename it.",
        "",
        "\033[0;33mExample input:\033[0m",
        "\033[0;32mmy_custom_model.safetensors\033[0m   (or just press ENTER)",
    ])
    print()
    new_name = input("New filename (press ENTER to skip): ").strip()
    
    return url, folder, new_name


def add_model(url: str, folder: str, new_name: str = ""):
    """Add a model to the YAML config file."""
    # Validate folder
    if folder not in VALID_FOLDERS:
        LOGGER.error("invalid_folder", folder=folder, valid_folders=VALID_FOLDERS)
        sys.exit(1)

    # Determine filename
    if new_name:
        filename = new_name
    else:
        filename = extract_filename(url)
        if not filename:
            LOGGER.error("filename_extraction_failed", url=url, hint="Please provide a filename")
            sys.exit(1)

    # Load existing config
    if CONFIG_FILE.exists():
        with open(CONFIG_FILE, "r") as f:
            config = yaml.safe_load(f) or {}
    else:
        config = {}

    # Check if already exists
    if folder in config:
        for item in config[folder]:
            if isinstance(item, dict) and item.get("name") == filename:
                LOGGER.warning("model_exists", folder=folder, name=filename)
                response = input("Add anyway? [y/N] ").strip().lower()
                if response != "y":
                    LOGGER.info("cancelled")
                    sys.exit(0)
                break

    # Add to config
    if folder not in config:
        config[folder] = []
    
    config[folder].append({
        "url": url,
        "name": filename,
    })

    # Write back
    with open(CONFIG_FILE, "w") as f:
        yaml.dump(config, f, default_flow_style=False, sort_keys=False)

    LOGGER.info("model_added", config_file=str(CONFIG_FILE), folder=folder, name=filename)
    LOGGER.info("tip", message="Run 'make download-models' to download")


def main():
    if len(sys.argv) < 2:
        # Interactive mode
        url, folder, new_name = interactive_mode()
        add_model(url, folder, new_name)
    elif len(sys.argv) >= 3:
        # Direct mode
        url = sys.argv[1]
        folder = sys.argv[2]
        new_name = sys.argv[3] if len(sys.argv) > 3 else ""
        add_model(url, folder, new_name)
    else:
        LOGGER.info("usage", interactive="python add_model.py", direct="python add_model.py <url> <folder> [filename]")
        sys.exit(1)


if __name__ == "__main__":
    main()
