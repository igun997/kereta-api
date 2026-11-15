#!/usr/bin/env python3
"""Generate an image via the OpenAI-compatible endpoint in .env (URL, KEY).

Usage:
  python3 tools/genimg.py OUT.png "prompt" [--model cx/gpt-6.1-sol] [--size 1024x1024] [--n 1]

The secret is read from .env and never printed.
"""
import argparse, base64, json, pathlib, sys, urllib.request

ROOT = pathlib.Path(__file__).resolve().parent.parent


def load_env():
    env = {}
    for line in (ROOT / ".env").read_text().splitlines():
        line = line.strip()
        if line and not line.startswith("#") and "=" in line:
            k, v = line.split("=", 1)
            env[k.strip()] = v.strip().strip('"').strip("'")
    return env


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("out")
    ap.add_argument("prompt")
    ap.add_argument("--model", default="cx/gpt-6.1-sol")
    ap.add_argument("--size", default="1024x1024")
    ap.add_argument("--n", type=int, default=1)
    a = ap.parse_args()

    env = load_env()
    base = env["URL"].rstrip("/")
    if not base.endswith("/v1"):
        base += "/v1"
    req = urllib.request.Request(
        base + "/images/generations",
        data=json.dumps({"model": a.model, "prompt": a.prompt, "size": a.size, "n": a.n}).encode(),
        headers={"Authorization": "Bearer " + env["KEY"], "Content-Type": "application/json", "User-Agent": "curl/8.5.0"},
    )
    with urllib.request.urlopen(req, timeout=300) as r:
        data = json.load(r)["data"]
    out = pathlib.Path(a.out)
    out.parent.mkdir(parents=True, exist_ok=True)
    for i, d in enumerate(data):
        p = out if len(data) == 1 else out.with_name(f"{out.stem}_{i}{out.suffix}")
        p.write_bytes(base64.b64decode(d["b64_json"]))
        print("wrote", p)


if __name__ == "__main__":
    sys.exit(main())
