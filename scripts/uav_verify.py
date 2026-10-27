#!/usr/bin/env python3
"""Validate exact core submodule revisions before building."""
import json
import subprocess
from pathlib import Path

root = Path(__file__).resolve().parent.parent
specs = json.loads((root / "uav/versions.json").read_text())
for spec in specs:
    if "/references/" in spec["path"]:
        continue
    path = root / spec["path"]
    # An uninitialized directory may resolve to the parent Git repository.
    if not (path / ".git").exists():
        raise SystemExit(f"源码未下载: {spec['path']}；先运行 bash scripts/uav_fetch.sh")
    sha = subprocess.check_output(["git", "-C", str(path), "rev-parse", "HEAD"], text=True).strip()
    if sha != spec["sha"]:
        raise SystemExit(f"版本不匹配: {spec['path']}\n预期 {spec['sha']}\n实际 {sha}")
    dirty = subprocess.check_output(["git", "-C", str(path), "status", "--porcelain", "--untracked-files=no"], text=True)
    if dirty:
        raise SystemExit(f"子模块存在已跟踪文件修改，请先检查: {spec['path']}")
    print(f"OK {spec['path']} {sha[:12]}")
