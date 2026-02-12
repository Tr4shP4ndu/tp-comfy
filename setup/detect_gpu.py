#!/usr/bin/env python3
"""
Detect GPU and recommend PyTorch installation.
Usage: python detect_gpu.py [--install] [--check] [--nightly]
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

# Available PyTorch CUDA versions (stable releases)
AVAILABLE_CUDA_VERSIONS = ["cu118", "cu121", "cu124", "cu126", "cu128", "cu130"]

# PyTorch CUDA version mappings (driver CUDA version -> recommended PyTorch CUDA)
# Always map to the highest available PyTorch CUDA that's <= driver CUDA
CUDA_PYTORCH_MAP = {
    "13": "cu130",  # CUDA 13.x - use cu130
    "12": "cu128",  # CUDA 12.x - use cu128 (latest 12.x)
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


def get_installed_pytorch_info() -> dict | None:
    """Check currently installed PyTorch version and CUDA support."""
    try:
        result = subprocess.run(
            [sys.executable, "-c", """
import torch
print(f"version:{torch.__version__}")
print(f"cuda_available:{torch.cuda.is_available()}")
print(f"cuda_version:{torch.version.cuda if torch.cuda.is_available() else 'N/A'}")
if torch.cuda.is_available():
    print(f"device_name:{torch.cuda.get_device_name(0)}")
    print(f"device_count:{torch.cuda.device_count()}")
"""],
            capture_output=True,
            text=True,
            timeout=30
        )
        if result.returncode != 0:
            return None
        
        info = {}
        for line in result.stdout.strip().split("\n"):
            if ":" in line:
                key, value = line.split(":", 1)
                info[key] = value
        return info
    except Exception:
        return None


def get_pytorch_install_command(gpu_info: dict | None, use_nightly: bool = False) -> tuple[str, list[str]]:
    """Get the recommended PyTorch installation command."""
    if gpu_info is None:
        return "cpu", [
            "uv", "pip", "install",
            "torch", "torchvision", "torchaudio",
            "--index-url", "https://download.pytorch.org/whl/cpu"
        ]
    
    if gpu_info["type"] == "nvidia":
        cuda_major = gpu_info.get("cuda_version", "12").split(".")[0]
        pytorch_cuda = CUDA_PYTORCH_MAP.get(cuda_major, "cu128")
        
        if use_nightly:
            # Nightly builds may have newer CUDA support
            return f"cuda-nightly ({pytorch_cuda})", [
                "uv", "pip", "install", "--pre",
                "torch", "torchvision", "torchaudio",
                "--index-url", f"https://download.pytorch.org/whl/nightly/{pytorch_cuda}"
            ]
        
        # cu130 uses --extra-index-url, others use --index-url
        if pytorch_cuda == "cu130":
            return f"cuda ({pytorch_cuda})", [
                "uv", "pip", "install",
                "torch", "torchvision", "torchaudio",
                "--extra-index-url", f"https://download.pytorch.org/whl/{pytorch_cuda}"
            ]
        
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
    check_mode = "--check" in sys.argv
    use_nightly = "--nightly" in sys.argv
    
    print()
    print("=" * 60)
    print("GPU & PyTorch Detection")
    print("=" * 60)
    
    # Check currently installed PyTorch
    pytorch_info = get_installed_pytorch_info()
    if pytorch_info:
        print()
        print("Currently installed PyTorch:")
        print(f"  Version:      {pytorch_info.get('version', 'unknown')}")
        print(f"  CUDA enabled: {pytorch_info.get('cuda_available', 'unknown')}")
        print(f"  CUDA version: {pytorch_info.get('cuda_version', 'N/A')}")
        if pytorch_info.get('device_name'):
            print(f"  GPU device:   {pytorch_info.get('device_name')}")
    else:
        print()
        print("Currently installed PyTorch: Not found")
    
    # Detect GPU
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
    print()
    if gpu_info is None:
        print("Detected GPU: None (will use CPU)")
    else:
        print(f"Detected GPU: {gpu_info.get('name', 'Unknown')}")
        if gpu_info.get("type") == "nvidia":
            print(f"  Driver:       {gpu_info.get('driver', 'unknown')}")
            print(f"  CUDA version: {gpu_info.get('cuda_version', 'unknown')}")
            print(f"  Memory:       {gpu_info.get('memory', 'unknown')}")
        LOGGER.info("gpu_detected", **gpu_info)
    
    # Get install command
    backend, install_cmd = get_pytorch_install_command(gpu_info, use_nightly=use_nightly)
    
    print()
    print(f"Recommended PyTorch: {backend}")
    print(f"Available CUDA versions: {', '.join(AVAILABLE_CUDA_VERSIONS)}")
    
    # Show note if installed PyTorch doesn't match recommended
    if pytorch_info and gpu_info:
        installed_cuda = pytorch_info.get("cuda_version", "N/A")
        driver_cuda = gpu_info.get("cuda_version", "")
        if driver_cuda.startswith("13") and not installed_cuda.startswith("13"):
            print()
            print("NOTE: Your driver supports CUDA 13.x, but your PyTorch uses CUDA " + installed_cuda)
            print("      For best performance, run: make install-pytorch-cu130")
    
    if check_mode:
        # Just check, don't install
        print()
        print("=" * 60)
        return
    
    if install_mode:
        print()
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
        print("Or use one of these make commands:")
        print("  make install-pytorch          # Auto-detect and install")
        print("  make install-pytorch-cu130    # Force CUDA 13.0")
        print("  make install-pytorch-cu128    # Force CUDA 12.8")
        print("  make install-pytorch-cu124    # Force CUDA 12.4")
        print("  make install-pytorch-cu118    # Force CUDA 11.8")
        print("  make install-pytorch-cpu      # CPU only")
    
    print()
    print("=" * 60)
    
    # Output for Makefile parsing
    if "--output-backend" in sys.argv:
        print(backend.split()[0])  # Just "cuda", "mps", "rocm", or "cpu"


if __name__ == "__main__":
    main()
