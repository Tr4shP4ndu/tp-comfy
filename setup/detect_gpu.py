#!/usr/bin/env python3
"""
Detect GPU and recommend PyTorch installation.
Usage: python detect_gpu.py [--install]
"""

import subprocess
import sys
import platform
import re

import structlog

# Configure structlog
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

# PyTorch CUDA version mappings (driver CUDA version -> recommended PyTorch CUDA)
CUDA_PYTORCH_MAP = {
    "13": "cu124",  # CUDA 13.x drivers work best with PyTorch CUDA 12.4
    "12": "cu124",  # CUDA 12.x
    "11": "cu118",  # CUDA 11.x
}


def run_command(cmd: list[str]) -> tuple[int, str, str]:
    """Run a command and return exit code, stdout, stderr."""
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=10)
        return result.returncode, result.stdout, result.stderr
    except (subprocess.TimeoutExpired, FileNotFoundError):
        return -1, "", ""


def detect_nvidia_gpu() -> dict | None:
    """Detect NVIDIA GPU using nvidia-smi."""
    code, stdout, _ = run_command(["nvidia-smi", "--query-gpu=name,driver_version,memory.total", "--format=csv,noheader"])
    
    if code != 0:
        return None
    
    lines = stdout.strip().split("\n")
    if not lines or not lines[0]:
        return None
    
    parts = lines[0].split(", ")
    if len(parts) < 3:
        return None
    
    # Get CUDA version from nvidia-smi
    code, stdout, _ = run_command(["nvidia-smi"])
    cuda_version = None
    if code == 0:
        match = re.search(r"CUDA Version:\s*(\d+\.\d+)", stdout)
        if match:
            cuda_version = match.group(1)
    
    return {
        "type": "nvidia",
        "name": parts[0].strip(),
        "driver": parts[1].strip(),
        "memory": parts[2].strip(),
        "cuda_version": cuda_version,
    }


def detect_apple_silicon() -> dict | None:
    """Detect Apple Silicon (M1/M2/M3/M4)."""
    if platform.system() != "Darwin":
        return None
    
    code, stdout, _ = run_command(["sysctl", "-n", "machdep.cpu.brand_string"])
    if code != 0:
        return None
    
    cpu_brand = stdout.strip()
    if "Apple" in cpu_brand:
        return {
            "type": "mps",
            "name": cpu_brand,
        }
    
    return None


def detect_amd_gpu() -> dict | None:
    """Detect AMD GPU (ROCm)."""
    code, stdout, _ = run_command(["rocm-smi", "--showproductname"])
    if code != 0:
        return None
    
    return {
        "type": "rocm",
        "name": stdout.strip(),
    }


def get_pytorch_install_command(gpu_info: dict | None) -> tuple[str, list[str]]:
    """Get the recommended PyTorch installation command."""
    if gpu_info is None:
        return "cpu", [
            "uv", "pip", "install",
            "torch", "torchvision", "torchaudio",
            "--index-url", "https://download.pytorch.org/whl/cpu"
        ]
    
    if gpu_info["type"] == "nvidia":
        cuda_major = gpu_info.get("cuda_version", "12").split(".")[0]
        pytorch_cuda = CUDA_PYTORCH_MAP.get(cuda_major, "cu124")
        
        return f"cuda ({pytorch_cuda})", [
            "uv", "pip", "install",
            "torch", "torchvision", "torchaudio",
            "--index-url", f"https://download.pytorch.org/whl/{pytorch_cuda}"
        ]
    
    if gpu_info["type"] == "mps":
        # Apple Silicon uses default PyTorch (MPS support built-in)
        return "mps", [
            "uv", "pip", "install",
            "torch", "torchvision", "torchaudio"
        ]
    
    if gpu_info["type"] == "rocm":
        return "rocm", [
            "uv", "pip", "install",
            "torch", "torchvision", "torchaudio",
            "--index-url", "https://download.pytorch.org/whl/rocm6.2"
        ]
    
    return "cpu", [
        "uv", "pip", "install",
        "torch", "torchvision", "torchaudio"
    ]


def main():
    install_mode = "--install" in sys.argv
    
    LOGGER.info("detecting_gpu")
    
    # Try NVIDIA first
    gpu_info = detect_nvidia_gpu()
    
    # Try Apple Silicon
    if gpu_info is None:
        gpu_info = detect_apple_silicon()
    
    # Try AMD ROCm
    if gpu_info is None:
        gpu_info = detect_amd_gpu()
    
    # Report findings
    if gpu_info is None:
        LOGGER.warning("no_gpu_detected", fallback="CPU mode")
    else:
        LOGGER.info("gpu_detected", **gpu_info)
    
    # Get install command
    backend, install_cmd = get_pytorch_install_command(gpu_info)
    LOGGER.info("recommended_pytorch", backend=backend)
    
    if install_mode:
        LOGGER.info("installing_pytorch", command=" ".join(install_cmd))
        result = subprocess.run(install_cmd)
        if result.returncode == 0:
            LOGGER.info("pytorch_installed", backend=backend)
        else:
            LOGGER.error("pytorch_install_failed", exit_code=result.returncode)
            sys.exit(result.returncode)
    else:
        print()
        print("To install PyTorch, run:")
        print(f"  {' '.join(install_cmd)}")
        print()
        print("Or use: make install-pytorch")
    
    # Output for Makefile parsing
    if "--output-backend" in sys.argv:
        print(backend.split()[0])  # Just "cuda", "mps", "rocm", or "cpu"


if __name__ == "__main__":
    main()
