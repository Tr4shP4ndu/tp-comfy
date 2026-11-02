#!/usr/bin/env python3
"""
Check and test the LipSync (LTX-2.3 Dub-It) workflow
Usage:
  python lipsync.py check [--url URL]
  python lipsync.py test --clip FILE [--prompt TEXT] [--seconds N] [--preset 32gb|24gb|preview] [--seed N] [--url URL]
"""

import argparse
import json
import os
import shutil
import subprocess
import sys
import tempfile
import time
import urllib.error
import urllib.parse
import urllib.request
import uuid
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

ROOT = Path(__file__).resolve().parent.parent
DATA_DIR = ROOT / "data"
WORKFLOW_UI = ROOT / "LipSync - LTX-2.3 Dub-It.json"
WORKFLOW_API = ROOT / "LipSync - LTX-2.3 Dub-It (API).json"
MODELS_CONFIG = ROOT / "setup" / "models-lipsync.yaml"
REQUIRED_NODES = ["ComfyUI-LTXVideo", "ComfyUI-KJNodes"]

# Frontend-only node types: they never reach the server
FRONTEND_ONLY = {"MarkdownNote", "Note", "Reroute", "PrimitiveNode"}

# s1 = low-res pass, s2 = high-res output (always 2x s1), 16:9
PRESETS = {
    "32gb": (960, 544),
    "24gb": (768, 448),
    "preview": (640, 352),
}


# ============================================================================
# COMFYUI API
# ============================================================================

def api_get(url: str, path: str, timeout: float = 10) -> dict:
    with urllib.request.urlopen(f"{url}{path}", timeout=timeout) as resp:
        return json.load(resp)


def api_post(url: str, path: str, payload: dict) -> dict:
    req = urllib.request.Request(
        f"{url}{path}",
        data=json.dumps(payload).encode(),
        headers={"Content-Type": "application/json"},
    )
    with urllib.request.urlopen(req, timeout=30) as resp:
        return json.load(resp)


def is_local(url: str) -> bool:
    return urllib.parse.urlparse(url).hostname in ("127.0.0.1", "localhost", "::1")


def upload_file(url: str, path: Path, name: str) -> str:
    """Upload a file to ComfyUI's input folder (works for video too). Returns the stored name."""
    boundary = uuid.uuid4().hex
    parts = [
        f'--{boundary}\r\nContent-Disposition: form-data; name="type"\r\n\r\ninput\r\n'.encode(),
        f'--{boundary}\r\nContent-Disposition: form-data; name="overwrite"\r\n\r\ntrue\r\n'.encode(),
        f'--{boundary}\r\nContent-Disposition: form-data; name="image"; filename="{name}"\r\n'
        f"Content-Type: application/octet-stream\r\n\r\n".encode(),
        path.read_bytes(),
        f"\r\n--{boundary}--\r\n".encode(),
    ]
    req = urllib.request.Request(
        f"{url}/upload/image",
        data=b"".join(parts),
        headers={"Content-Type": f"multipart/form-data; boundary={boundary}"},
    )
    with urllib.request.urlopen(req, timeout=300) as resp:
        return json.load(resp)["name"]


def download_output(url: str, item: dict, out_dir: Path) -> Path:
    query = urllib.parse.urlencode({
        "filename": item["filename"],
        "subfolder": item.get("subfolder", ""),
        "type": item.get("type", "output"),
    })
    out_dir.mkdir(parents=True, exist_ok=True)
    dst = out_dir / item["filename"]
    with urllib.request.urlopen(f"{url}/view?{query}", timeout=300) as resp, open(dst, "wb") as f:
        shutil.copyfileobj(resp, f)
    return dst


def server_up(url: str) -> bool:
    try:
        api_get(url, "/system_stats", timeout=3)
        return True
    except (urllib.error.URLError, OSError):
        return False


def combo_options(spec) -> list:
    """Return the choices of a combo input from /object_info (old and new formats)."""
    if not isinstance(spec, list) or not spec:
        return []
    if isinstance(spec[0], list):
        return spec[0]
    if spec[0] == "COMBO" and len(spec) > 1 and isinstance(spec[1], dict):
        return spec[1].get("options", [])
    return []


# ============================================================================
# CHECK
# ============================================================================

def log_vram(name: str, vram_gb: float) -> None:
    if vram_gb >= 30:
        LOGGER.info("gpu_ok", gpu=name, vram_gb=round(vram_gb), preset="32gb")
    elif vram_gb >= 22:
        LOGGER.warning("gpu_tight", gpu=name, vram_gb=round(vram_gb), hint="use PRESET=24gb")
    else:
        LOGGER.warning("gpu_small", gpu=name, vram_gb=round(vram_gb), hint="use PRESET=preview and make run-lowvram")


def check(url: str) -> int:
    if not is_local(url):
        # Files live on the server machine: ask the server instead of looking at this disk
        if not server_up(url):
            LOGGER.error("server_not_running", url=url, hint="run 'make run' on the GPU machine and check the firewall")
            return 1
        for device in api_get(url, "/system_stats").get("devices", []):
            log_vram(device.get("name", "?"), device.get("vram_total", 0) / 1024**3)
        return check_server(url, 0)

    problems = 0

    # GPU
    try:
        out = subprocess.run(
            ["nvidia-smi", "--query-gpu=name,memory.total", "--format=csv,noheader,nounits"],
            capture_output=True, text=True, timeout=10,
        )
        name, mem = [p.strip() for p in out.stdout.strip().split("\n")[0].split(",")]
        log_vram(name, int(mem) / 1024)
    except (FileNotFoundError, subprocess.TimeoutExpired, ValueError, IndexError):
        LOGGER.error("no_nvidia_gpu", hint="LTX-2.3 needs an NVIDIA GPU with CUDA (nvidia-smi not found)")
        problems += 1

    # Disk
    free_gb = shutil.disk_usage(DATA_DIR if DATA_DIR.exists() else ROOT).free / 1e9
    LOGGER.info("disk_free", gb=round(free_gb))

    # Custom nodes
    for node in REQUIRED_NODES:
        if (DATA_DIR / "custom_nodes" / node).is_dir():
            LOGGER.info("node_ok", node=node)
        else:
            LOGGER.error("node_missing", node=node, hint="make download-lipsync")
            problems += 1

    # Models
    with open(MODELS_CONFIG) as f:
        config = yaml.safe_load(f)
    for folder, models in config.items():
        for model in models or []:
            path = DATA_DIR / "models" / folder / model["name"]
            if not path.exists():
                LOGGER.error("model_missing", file=f"{folder}/{model['name']}", hint="make download-lipsync")
                problems += 1
            elif path.with_name(path.name + ".aria2").exists():
                LOGGER.error("model_incomplete", file=f"{folder}/{model['name']}", hint="re-run make download-lipsync to resume")
                problems += 1
            else:
                LOGGER.info("model_ok", file=f"{folder}/{model['name']}", gb=round(path.stat().st_size / 1e9, 1))

    if not server_up(url):
        LOGGER.warning("server_not_running", url=url, hint="start 'make run' in another terminal for the full check")
        return report(problems)
    return check_server(url, problems)


def check_server(url: str, problems: int) -> int:
    """Every node type and model filename in the workflow must resolve on the server."""
    object_info = api_get(url, "/object_info", timeout=60)
    workflow = json.loads(WORKFLOW_UI.read_text())
    for node in workflow["nodes"]:
        node_type = node["type"]
        if node_type in FRONTEND_ONLY:
            continue
        if node_type not in object_info:
            LOGGER.error("node_type_unknown", type=node_type, hint="update ComfyUI (make update) and install LTXVideo + KJNodes deps")
            problems += 1
            continue
        inputs = object_info[node_type]["input"]
        choices = [o for section in ("required", "optional") for spec in inputs.get(section, {}).values() for o in combo_options(spec)]
        for value in node.get("widgets_values") or []:
            if isinstance(value, str) and value.endswith(".safetensors") and value not in choices:
                LOGGER.error("model_not_visible", node=node_type, file=value, hint="on the server: make lipsync-setup")
                problems += 1
    LOGGER.info("server_checked", url=url, node_types=len({n["type"] for n in workflow["nodes"]}))
    return report(problems)


def report(problems: int) -> int:
    if problems:
        LOGGER.error("check_failed", problems=problems)
        return 1
    LOGGER.info("check_passed")
    return 0


# ============================================================================
# TEST
# ============================================================================

def trim_clip(src: Path, dst: Path, seconds: float) -> None:
    """Cut the first N seconds (keeps audio). Falls back to a plain copy without ffmpeg."""
    ffmpeg = shutil.which("ffmpeg")
    if not ffmpeg:
        try:
            import imageio_ffmpeg
            ffmpeg = imageio_ffmpeg.get_ffmpeg_exe()
        except ImportError:
            pass
    if not ffmpeg or seconds <= 0:
        shutil.copy(src, dst)
        return
    subprocess.run(
        [ffmpeg, "-y", "-loglevel", "error", "-i", str(src), "-t", str(seconds),
         "-c:v", "libx264", "-pix_fmt", "yuv420p", "-c:a", "aac", str(dst)],
        check=True,
    )


def patch_workflow(prompt: dict, clip_name: str, text: str | None, preset: str, seed: int | None) -> None:
    s1 = PRESETS[preset]
    s2 = (s1[0] * 2, s1[1] * 2)
    for node in prompt.values():
        node_type = node["class_type"]
        title = node.get("_meta", {}).get("title", "")
        inputs = node["inputs"]
        if node_type == "LoadVideo":
            inputs["file"] = clip_name
        elif node_type == "CLIPTextEncode" and "Positive" in title and text:
            inputs["text"] = text
        elif node_type == "RandomNoise" and seed is not None:
            inputs["noise_seed"] = seed
        elif node_type in ("ResizeImageMaskNode", "EmptyLTXVLatentVideo"):
            width, height = s2 if "s2" in title else s1
            for key in inputs:
                if key.endswith("width") and not isinstance(inputs[key], list):
                    inputs[key] = width
                elif key.endswith("height") and not isinstance(inputs[key], list):
                    inputs[key] = height


def test(url: str, clip: Path, text: str | None, seconds: float, preset: str, seed: int | None, out_dir: Path) -> int:
    if not clip.exists():
        LOGGER.error("clip_not_found", clip=str(clip))
        return 1
    if not WORKFLOW_API.exists():
        LOGGER.error(
            "api_workflow_missing",
            expected=WORKFLOW_API.name,
            how="make run -> open the LipSync workflow -> Workflow menu -> Export (API) -> save it in the repo root with that name",
        )
        return 1
    prompt = json.loads(WORKFLOW_API.read_text())
    if "nodes" in prompt:
        LOGGER.error("wrong_format", file=WORKFLOW_API.name, hint="this is the UI format; use Export (API), not Save/Export")
        return 1
    if not server_up(url):
        LOGGER.error("server_not_running", url=url, hint="start 'make run' in another terminal first")
        return 1

    # Upload the clip to ComfyUI's input folder (same call whether the server is local or remote)
    with tempfile.TemporaryDirectory() as tmp:
        trimmed = Path(tmp) / f"lipsync_test_{clip.stem}.mp4"
        trim_clip(clip, trimmed, seconds)
        clip_name = upload_file(url, trimmed, trimmed.name)
    LOGGER.info("clip_uploaded", file=f"input/{clip_name}", seconds=seconds or "full")

    patch_workflow(prompt, clip_name, text, preset, seed)

    # Queue
    try:
        queued = api_post(url, "/prompt", {"prompt": prompt, "client_id": str(uuid.uuid4())})
    except urllib.error.HTTPError as e:
        body = json.loads(e.read() or b"{}")
        LOGGER.error("queue_rejected", error=body.get("error", {}).get("message"))
        for node_id, info in body.get("node_errors", {}).items():
            for err in info.get("errors", []):
                LOGGER.error("node_error", node=node_id, type=info.get("class_type"), message=err.get("message"), details=err.get("details"))
        return 1
    prompt_id = queued["prompt_id"]
    LOGGER.info("queued", prompt_id=prompt_id, preset=preset, watch=url)

    # Wait for the result
    start = time.time()
    while True:
        time.sleep(5)
        history = api_get(url, f"/history/{prompt_id}").get(prompt_id)
        elapsed = int(time.time() - start)
        if not history:
            if elapsed % 30 < 5:
                LOGGER.info("running", elapsed_s=elapsed)
            continue
        status = history.get("status", {})
        if status.get("status_str") == "error":
            for kind, msg in status.get("messages", []):
                if kind == "execution_error":
                    LOGGER.error("execution_error", node=msg.get("node_type"), message=msg.get("exception_message", "").strip())
            return 1
        if status.get("completed"):
            break

    files = [
        item for output in history.get("outputs", {}).values()
        for items in output.values() if isinstance(items, list)
        for item in items if isinstance(item, dict) and "filename" in item
    ]
    for item in files:
        if is_local(url):
            LOGGER.info("output", file=str(Path("data/output") / item.get("subfolder", "") / item["filename"]))
        else:
            LOGGER.info("downloaded", file=str(download_output(url, item, out_dir)))
    LOGGER.info("test_passed", elapsed_s=int(time.time() - start))
    return 0


def main():
    parser = argparse.ArgumentParser(description="Check and test the LipSync workflow")
    parser.add_argument("--url", default=os.environ.get("COMFY_URL", "http://127.0.0.1:7860"))
    sub = parser.add_subparsers(dest="command", required=True)
    sub.add_parser("check", help="Preflight: GPU, nodes, models, server")
    t = sub.add_parser("test", help="Run the workflow on a clip through the ComfyUI API")
    t.add_argument("--clip", type=Path, required=True, help="Video of one person speaking")
    t.add_argument("--prompt", help='Shot description + speaking in <language> saying: "<new line>"')
    t.add_argument("--seconds", type=float, default=5, help="Trim the clip to N seconds (0 = full clip)")
    t.add_argument("--preset", choices=PRESETS, default="32gb")
    t.add_argument("--seed", type=int)
    t.add_argument("--out", type=Path, default=Path.home() / "Downloads", help="Where to save results from a remote server")
    args = parser.parse_args()

    url = args.url.rstrip("/")
    if args.command == "check":
        sys.exit(check(url))
    sys.exit(test(url, args.clip.expanduser().resolve(), args.prompt, args.seconds, args.preset, args.seed, args.out.expanduser()))


if __name__ == "__main__":
    main()
