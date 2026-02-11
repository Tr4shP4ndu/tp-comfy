#!/usr/bin/env python3
"""
Download/update ComfyUI custom nodes
Usage: python download_nodes.py [nodes_directory] [config_file]
"""

import subprocess
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


def extract_repo_name(url: str) -> str | None:
    """Extract repository name from GitHub URL."""
    url = url.rstrip("/").rstrip(".git")
    if "/" in url:
        return url.split("/")[-1]
    return None


def clone_or_pull(url: str, nodes_dir: Path) -> bool:
    """Clone a new repo or pull updates for existing one."""
    # Normalize URL
    if not url.endswith(".git"):
        url = f"{url}.git"
    
    repo_name = extract_repo_name(url)
    if not repo_name:
        LOGGER.error("invalid_url", url=url)
        return False

    target_dir = nodes_dir / repo_name

    if target_dir.exists():
        LOGGER.info("updating_node", repo=repo_name)
        result = subprocess.run(
            ["git", "-C", str(target_dir), "pull", "--ff-only"],
            capture_output=True,
            text=True,
        )
        if result.returncode != 0:
            LOGGER.warning("update_skipped", repo=repo_name, reason="already up to date or conflict")
    else:
        LOGGER.info("cloning_node", repo=repo_name)
        result = subprocess.run(
            [
                "git",
                "clone",
                "--depth=1",
                "--no-tags",
                "--recurse-submodules",
                "--shallow-submodules",
                url,
                str(target_dir),
            ],
            capture_output=True,
            text=True,
        )
        if result.returncode != 0:
            LOGGER.error("clone_failed", repo=repo_name, error=result.stderr.strip() if result.stderr else None)
            return False

    return True


def load_repos_from_yaml(config_file: Path) -> list[str]:
    """Load repository URLs from YAML config file."""
    with open(config_file, "r") as f:
        config = yaml.safe_load(f)
    
    repos = []
    for category, urls in config.items():
        if isinstance(urls, list):
            repos.extend(urls)
    
    return repos


def main():
    # Default paths
    nodes_dir = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("data/custom_nodes")
    config_file = Path(sys.argv[2]) if len(sys.argv) > 2 else Path("setup/nodes.yaml")

    # Convert to absolute paths
    nodes_dir = nodes_dir.resolve()
    
    # Create directory if it doesn't exist
    nodes_dir.mkdir(parents=True, exist_ok=True)

    LOGGER.info("download_nodes_start", nodes_dir=str(nodes_dir), config_file=str(config_file))

    # Check if config file exists
    if not config_file.exists():
        LOGGER.error("config_not_found", config_file=str(config_file))
        sys.exit(1)

    # Load repositories
    repos = load_repos_from_yaml(config_file)
    LOGGER.info("repos_found", count=len(repos))

    # Process repositories
    success_count = 0
    fail_count = 0

    for repo in repos:
        if clone_or_pull(repo, nodes_dir):
            success_count += 1
        else:
            fail_count += 1

    LOGGER.info(
        "download_nodes_complete",
        successful=success_count,
        failed=fail_count,
        nodes_dir=str(nodes_dir),
    )
    
    if fail_count == 0:
        LOGGER.info("tip", message="Run 'make install-node-deps' to install Python dependencies for custom nodes")


if __name__ == "__main__":
    main()
