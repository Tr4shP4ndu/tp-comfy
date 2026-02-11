#!/usr/bin/env python3
"""
Add a custom node repository to the download list
Usage:
  python add_node.py              # Interactive mode
  python add_node.py <github_url> # Direct mode
"""

import sys
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

CONFIG_FILE = Path("setup/nodes.yaml")

# Valid categories for nodes
VALID_CATEGORIES = [
    "manager",
    "utilities",
    "image_output",
    "prompt_styling",
    "upscaling",
    "controlnet_depth",
    "face_portrait",
    "segmentation",
    "video_animation",
    "vision_tagging",
    "advanced",
    "translation",
    "other",
]


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


def extract_repo_name(url: str) -> str | None:
    """Extract repository name from GitHub URL."""
    url = url.rstrip("/").rstrip(".git")
    if "/" in url:
        return url.split("/")[-1]
    return None


def interactive_mode() -> tuple[str, str]:
    """Run in interactive mode with prompts."""
    print("\n\033[0;32mAdd Custom Node\033[0m")
    print("=" * 15)
    print()
    
    print_box([
        "\033[0;33mSTEP 1: GitHub Repository URL\033[0m",
        "",
        "Paste the GitHub URL for the custom node repository.",
        "The .git extension is optional.",
        "",
        "\033[0;33mExample inputs:\033[0m",
        "\033[0;32mhttps://github.com/ltdrdata/ComfyUI-Manager\033[0m",
        "\033[0;32mhttps://github.com/cubiq/ComfyUI_essentials.git\033[0m",
    ])
    print()
    url = input("GitHub URL: ").strip()
    
    if not url:
        LOGGER.error("validation_failed", reason="URL is required")
        sys.exit(1)
    
    print()
    
    print_box([
        "\033[0;33mSTEP 2: Category\033[0m",
        "",
        "Which category does this node belong to?",
        "",
        "\033[0;33mOptions:\033[0m",
        "  manager, utilities, image_output, prompt_styling,",
        "  upscaling, controlnet_depth, face_portrait, segmentation,",
        "  video_animation, vision_tagging, advanced, translation, other",
        "",
        "\033[0;33mExample input:\033[0m",
        "\033[0;32mutilities\033[0m",
    ])
    print()
    category = input("Category (default: other): ").strip() or "other"
    
    return url, category


def add_node(url: str, category: str = "other"):
    """Add a custom node to the YAML config file."""
    # Normalize URL (remove .git if present for consistency)
    url = url.rstrip("/")
    if url.endswith(".git"):
        url = url[:-4]

    # Validate it looks like a GitHub URL
    if not url.startswith("https://github.com/") or url.count("/") < 4:
        LOGGER.error("invalid_url", url=url, expected_format="https://github.com/username/repo-name")
        sys.exit(1)

    # Validate category
    if category not in VALID_CATEGORIES:
        LOGGER.warning("unknown_category", category=category, using="other")
        category = "other"

    repo_name = extract_repo_name(url)

    # Load existing config
    if CONFIG_FILE.exists():
        with open(CONFIG_FILE, "r") as f:
            config = yaml.safe_load(f) or {}
    else:
        config = {}

    # Check if already exists in any category
    for cat, urls in config.items():
        if isinstance(urls, list):
            for existing_url in urls:
                existing_normalized = existing_url.rstrip("/").rstrip(".git").replace(".git", "")
                if existing_normalized == url:
                    LOGGER.warning("node_exists", repo=repo_name, category=cat)
                    sys.exit(0)

    # Add to config
    if category not in config:
        config[category] = []
    
    config[category].append(url)

    # Write back
    with open(CONFIG_FILE, "w") as f:
        yaml.dump(config, f, default_flow_style=False, sort_keys=False)

    LOGGER.info("node_added", config_file=str(CONFIG_FILE), repo=repo_name, category=category)
    LOGGER.info("tip", message="Run 'make download-nodes' to download")


def main():
    if len(sys.argv) < 2:
        # Interactive mode
        url, category = interactive_mode()
        add_node(url, category)
    else:
        # Direct mode
        url = sys.argv[1]
        category = sys.argv[2] if len(sys.argv) > 2 else "other"
        add_node(url, category)


if __name__ == "__main__":
    main()
