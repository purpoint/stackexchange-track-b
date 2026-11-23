#!/usr/bin/env python3
"""Download the Ask Ubuntu archive from the assigned Stack Exchange dump."""

import argparse
import hashlib
import json
import urllib.request
from pathlib import Path

URL = "https://archive.org/download/stackexchange/askubuntu.com.7z"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--destination", type=Path, default=Path("data/archives/askubuntu.com.7z"))
    args = parser.parse_args()
    args.destination.parent.mkdir(parents=True, exist_ok=True)
    request = urllib.request.Request(URL, headers={"User-Agent": "BCS714D-TrackB/1.0"})
    temporary = args.destination.with_suffix(args.destination.suffix + ".partial")
    total = 0
    digest = hashlib.sha256()
    with urllib.request.urlopen(request, timeout=120) as response, temporary.open("wb") as output:
        while True:
            block = response.read(4 * 1024 * 1024)
            if not block:
                break
            output.write(block)
            digest.update(block)
            total += len(block)
            print(f"downloaded_bytes={total}", flush=True)
    temporary.replace(args.destination)
    manifest = {
        "source_url": URL,
        "archive": str(args.destination),
        "bytes": total,
        "sha256": digest.hexdigest(),
    }
    manifest_path = args.destination.parent / "MANIFEST-askubuntu.json"
    manifest_path.write_text(json.dumps(manifest, indent=2), encoding="utf-8")
    print(f"saved={args.destination}")
    print(f"manifest={manifest_path}")


if __name__ == "__main__":
    main()
