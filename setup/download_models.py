#!/usr/bin/env python3
"""
Download ComfyUI models using aria2c
Usage: python download_models.py [models_directory] [config_file]
"""

import subprocess
import sys
import tempfile
from pathlib import Path

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


def load_models_from_yaml(config_file: Path) -> list[dict]:
    """Load models from YAML config file."""
    with open(config_file, "r") as f:
        config = yaml.safe_load(f)
    
    models = []
    for folder, items in config.items():
        if isinstance(items, list):
            for item in items:
                if isinstance(item, dict) and "url" in item:
                    models.append({
                        "url": item["url"],
                        "folder": folder,
                        "name": item.get("name"),
                    })
    
    return models


def generate_aria2_input(models: list[dict]) -> str:
    """Generate aria2c input file content from models list."""
    lines = []
    for model in models:
        lines.append(model["url"])
        output_path = f"{model['folder']}/{model['name']}" if model.get("name") else model["folder"]
        lines.append(f"  out={output_path}")
    return "\n".join(lines)


def main():
    # Default paths
    models_dir = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("data/models")
    config_file = Path(sys.argv[2]) if len(sys.argv) > 2 else Path("setup/models.yaml")

    # Convert to absolute paths
    models_dir = models_dir.resolve()
    
    # Create directory if it doesn't exist
    models_dir.mkdir(parents=True, exist_ok=True)

    LOGGER.info("download_models_start", models_dir=str(models_dir), config_file=str(config_file))

    # Check if config file exists
    if not config_file.exists():
        LOGGER.error("config_not_found", config_file=str(config_file))
        sys.exit(1)

    # Load models
    models = load_models_from_yaml(config_file)
    LOGGER.info("models_found", count=len(models))

    # Generate aria2c input file
    aria2_content = generate_aria2_input(models)
    
    # Write to temp file and run aria2c
    with tempfile.NamedTemporaryFile(mode="w", suffix=".txt", delete=False) as f:
        f.write(aria2_content)
        temp_file = f.name

    LOGGER.info("starting_download", tool="aria2c")
    
    try:
        result = subprocess.run(
            [
                "aria2c",
                "-x", "10",
                "--disable-ipv6",
                "--input-file", temp_file,
                "--dir", str(models_dir),
                "--continue=true",
            ],
            check=False,
        )
        
        if result.returncode == 0:
            LOGGER.info("download_models_complete", models_dir=str(models_dir))
        else:
            LOGGER.error("download_failed", exit_code=result.returncode)
            sys.exit(result.returncode)
    finally:
        # Clean up temp file
        Path(temp_file).unlink(missing_ok=True)


if __name__ == "__main__":
    main()
