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

CONFIG_FILE = Path("setup/nodes.txt")


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


def interactive_mode() -> str:
    """Run in interactive mode with prompts."""
    print("\n\033[0;32mAdd Custom Node\033[0m")
    print("=" * 15)
    print()
    
    print_box([
        "\033[0;33mGitHub Repository URL\033[0m",
        "",
        "Paste the GitHub URL for the custom node repository.",
        "The .git extension is optional.",
        "",
        "\033[0;33mExample inputs:\033[0m",
        "\033[0;32mhttps://github.com/ltdrdata/ComfyUI-Manager\033[0m",
        "\033[0;32mhttps://github.com/cubiq/ComfyUI_essentials.git\033[0m",
        "\033[0;32mhttps://github.com/Kosinkadink/ComfyUI-VideoHelperSuite\033[0m",
    ])
    print()
    url = input("GitHub URL: ").strip()
    
    if not url:
        LOGGER.error("validation_failed", reason="URL is required")
        sys.exit(1)
    
    return url


def add_node(url: str):
    """Add a custom node to the config file."""
    # Normalize URL (add .git if missing)
    if not url.endswith(".git"):
        url = f"{url}.git"

    # Validate it looks like a GitHub URL
    if not url.startswith("https://github.com/") or url.count("/") < 4:
        LOGGER.error("invalid_url", url=url, expected_format="https://github.com/username/repo-name.git")
        sys.exit(1)

    repo_name = extract_repo_name(url)

    # Check if already exists in config
    if CONFIG_FILE.exists():
        content = CONFIG_FILE.read_text()
        if url in content:
            LOGGER.warning("node_exists", repo=repo_name)
            sys.exit(0)

    # Add to config file
    with open(CONFIG_FILE, "a") as f:
        f.write(f"{url}\n")

    LOGGER.info("node_added", config_file=str(CONFIG_FILE), repo=repo_name, url=url)
    LOGGER.info("tip", message="Run 'make download-nodes' to download")


def main():
    if len(sys.argv) < 2:
        # Interactive mode
        url = interactive_mode()
        add_node(url)
    else:
        # Direct mode
        url = sys.argv[1]
        add_node(url)


if __name__ == "__main__":
    main()
