#!/usr/bin/env python3
"""List or download the .7z community files from the assigned Archive.org item."""

import argparse
import json
import os
import sys
import urllib.parse
import urllib.request
from datetime import datetime, timezone
from pathlib import Path

IDENTIFIER = "stackexchange"
METADATA_URL = f"https://archive.org/metadata/{IDENTIFIER}"


def read_metadata():
    request = urllib.request.Request(METADATA_URL, headers={"User-Agent": "BCS714D-TrackB/1.0"})
    with urllib.request.urlopen(request, timeout=60) as response:
        return json.load(response)


def archive_files(metadata):
    files = []
    for item in metadata.get("files", []):
        name = item.get("name", "")
        if name.lower().endswith(".7z") and not name.startswith("../"):
            files.append(
                {
                    "name": name,
                    "size": int(item.get("size", 0) or 0),
                    "sha1": item.get("sha1"),
                    "mtime": item.get("mtime"),
                }
            )
    return sorted(files, key=lambda item: item["name"].lower())


def download_one(item, destination):
    name = item["name"]
    target = destination / Path(name).name
    if target.exists() and target.stat().st_size == item["size"] and item["size"] > 0:
        return target

    url = f"https://archive.org/download/{IDENTIFIER}/{urllib.parse.quote(name)}"
    request = urllib.request.Request(url, headers={"User-Agent": "BCS714D-TrackB/1.0"})
    temporary = target.with_suffix(target.suffix + ".partial")
    with urllib.request.urlopen(request, timeout=120) as response, temporary.open("wb") as output:
        while True:
            block = response.read(4 * 1024 * 1024)
            if not block:
                break
            output.write(block)
    actual = temporary.stat().st_size
    if item["size"] and actual != item["size"]:
        temporary.unlink(missing_ok=True)
        raise IOError(f"Size mismatch for {name}: expected {item['size']}, got {actual}")
    temporary.replace(target)
    return target


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--destination", type=Path, default=Path("data/archives"))
    parser.add_argument("--download-all", action="store_true", help="Download every .7z community archive")
    parser.add_argument("--minimum-free-gib", type=float, default=120.0)
    args = parser.parse_args()

    metadata = read_metadata()
    files = archive_files(metadata)
    if not files:
        raise SystemExit("No .7z files were found in the assigned Archive.org item.")

    total_bytes = sum(item["size"] for item in files)
    print(f"Archive item: {IDENTIFIER}")
    print(f"Community .7z files: {len(files)}")
    print(f"Listed compressed size: {total_bytes / (1024 ** 3):.2f} GiB")
    print(f"Archive metadata date: {metadata.get('metadata', {}).get('date', 'not provided')}")
    print("Download is not started unless --download-all is supplied.")
    for item in files:
        print(f"{item['size']:>14}  {item['name']}")

    if not args.download_all:
        return

    args.destination.mkdir(parents=True, exist_ok=True)
    free_bytes = os.statvfs(args.destination).f_bavail * os.statvfs(args.destination).f_frsize
    if free_bytes < args.minimum_free_gib * (1024 ** 3):
        raise SystemExit(
            f"Only {free_bytes / (1024 ** 3):.1f} GiB is free at the destination. "
            f"The configured safety floor is {args.minimum_free_gib:.1f} GiB."
        )

    manifest = {
        "identifier": IDENTIFIER,
        "retrieved_utc": datetime.now(timezone.utc).isoformat(),
        "archive_metadata_date": metadata.get("metadata", {}).get("date"),
        "files": [],
    }
    for index, item in enumerate(files, start=1):
        target = download_one(item, args.destination)
        print(f"[{index}/{len(files)}] saved {target.name}", flush=True)
        manifest["files"].append({**item, "local_path": str(target)})

    manifest_path = args.destination / "MANIFEST.json"
    manifest_path.write_text(json.dumps(manifest, indent=2), encoding="utf-8")
    print(f"Manifest: {manifest_path}")


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        print(f"download_archive.py: {error}", file=sys.stderr)
        raise
