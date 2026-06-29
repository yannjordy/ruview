#!/usr/bin/env python3
"""Télécharge le code source Rust des crates v2/ via GitHub API.

Usage: python scripts/download-crates.py [crate1 crate2 ...]
  Sans argument : télécharge tout
  Avec arguments : télécharge seulement les crates listés
  Ex: python scripts/download-crates.py wifi-densepose-core wifi-densepose-signal
"""

import os
import json
import urllib.request
import urllib.error
import sys
import time
import subprocess

OWNER = "ruvnet"
REPO = "ruview"
BRANCH = "main"
BASE_URL = f"https://api.github.com/repos/{OWNER}/{REPO}/contents/v2/crates"
OUTPUT = "/home/jordy/ruview/v2/crates"

# Get auth token from gh CLI
try:
    TOKEN = subprocess.check_output(["gh", "auth", "token"], text=True).strip()
except Exception:
    TOKEN = None

HEADERS = {
    "User-Agent": "Aetheris/1.0",
    "Accept": "application/vnd.github.v3+json",
}
if TOKEN:
    HEADERS["Authorization"] = f"token {TOKEN}"

SKIP_PATTERNS = [
    ".exe", ".bin", ".o", ".so", ".dylib", ".dll",
    ".pdb", ".wasm", ".pt", ".onnx", ".safetensors",
    ".npy", ".npz", ".h5", ".pkl",
    ".tar.gz", ".zip", ".7z",
    ".png", ".jpg", ".jpeg", ".gif", ".svg", ".ico",
    ".mp4", ".mp3", ".wav", ".flac",
    ".csv", ".jsonl", ".parquet",
    "__pycache__",
]

TARGET_CRATES = sys.argv[1:] if len(sys.argv) > 1 else None
TOTAL_FILES = 0
TOTAL_BYTES = 0


def should_skip(name):
    for p in SKIP_PATTERNS:
        if name.endswith(p) or p in name:
            return True
    return False


def download_file(url, path):
    global TOTAL_FILES, TOTAL_BYTES
    try:
        req = urllib.request.Request(url, headers=HEADERS)
        with urllib.request.urlopen(req, timeout=30) as resp:
            data = resp.read()
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, "wb") as f:
            f.write(data)
        TOTAL_FILES += 1
        TOTAL_BYTES += len(data)
        kb = len(data) / 1024
        print(f"  ✓ {os.path.basename(path)} ({kb:.1f} KB)")
        return True
    except urllib.error.HTTPError as e:
        if e.code == 403 and "rate limit" in str(e).lower():
            print("  ⚠ Rate limit atteint, pause 60s...")
            time.sleep(60)
            return download_file(url, path)
        print(f"  ✗ {os.path.basename(path)}: HTTP {e.code}")
        return False
    except Exception as e:
        print(f"  ✗ {os.path.basename(path)}: {e}")
        return False


def process_item(item, base_path):
    if item["type"] == "file":
        name = item["name"]
        if should_skip(name):
            return
        if name == "Cargo.toml" or name.endswith(".rs"):
            file_path = os.path.join(base_path, name)
            download_file(item["download_url"], file_path)
        return

    if item["type"] == "dir":
        dir_path = os.path.join(base_path, item["name"])
        list_url = item["url"]
        try:
            req = urllib.request.Request(list_url, headers=HEADERS)
            with urllib.request.urlopen(req, timeout=30) as resp:
                children = json.loads(resp.read().decode())
            time.sleep(0.1)
            for child in children:
                process_item(child, dir_path)
        except Exception as e:
            print(f"  ✗ Dossier {item['name']}: {e}")


def download_crate(crate_name):
    global TOTAL_FILES, TOTAL_BYTES
    crate_url = f"{BASE_URL}/{crate_name}"
    crate_path = os.path.join(OUTPUT, crate_name)
    print(f"\n📦 {crate_name}")

    try:
        req = urllib.request.Request(crate_url, headers=HEADERS)
        with urllib.request.urlopen(req, timeout=30) as resp:
            items = json.loads(resp.read().decode())
        time.sleep(0.1)

        for item in items:
            process_item(item, crate_path)

        if TOTAL_FILES > 0:
            print(f"  → {TOTAL_FILES} fichiers, {TOTAL_BYTES/1024:.0f} KB")
        else:
            print(f"  → Aucun fichier Rust trouvé")
        return True
    except urllib.error.HTTPError as e:
        print(f"  ✗ ERREUR: HTTP {e.code}")
        return False
    except Exception as e:
        print(f"  ✗ ERREUR: {e}")
        return False


def main():
    global TARGET_CRATES

    crates_url = BASE_URL
    try:
        req = urllib.request.Request(crates_url, headers=HEADERS)
        with urllib.request.urlopen(req, timeout=30) as resp:
            all_crates = json.loads(resp.read().decode())
        crate_names = [c["name"] for c in all_crates if c["type"] == "dir"]
    except Exception as e:
        print(f"Erreur listing crates: {e}")
        return

    if TARGET_CRATES:
        crate_names = [c for c in crate_names if c in TARGET_CRATES]
        missing = set(TARGET_CRATES) - set(crate_names)
        if missing:
            print(f"Crates introuvables: {missing}")

    print(f"\n{'='*50}")
    print(f"Aetheris — Downloader v2/ Rust Crates")
    print(f"Source: {OWNER}/{REPO} branch={BRANCH}")
    print(f"Cibles: {len(crate_names)} crates")
    print(f"{'='*50}\n")

    start = time.time()
    total_files = 0
    total_bytes = 0

    for i, name in enumerate(crate_names):
        global TOTAL_FILES, TOTAL_BYTES
        TOTAL_FILES = 0
        TOTAL_BYTES = 0
        download_crate(name)
        total_files += TOTAL_FILES
        total_bytes += TOTAL_BYTES

    elapsed = time.time() - start
    print(f"\n{'='*50}")
    print(f"Terminé en {elapsed:.0f}s")
    print(f"Total: {total_files} fichiers, {total_bytes/1024:.0f} KB")
    print(f"Dossier: {OUTPUT}")
    print(f"{'='*50}")


if __name__ == "__main__":
    main()
