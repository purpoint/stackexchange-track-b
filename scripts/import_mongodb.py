#!/usr/bin/env python3
"""Stream the Posts.xml records to MongoDB as JSON Lines."""

import argparse
import shutil
import subprocess
import sys
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[1]
CONVERTER = PROJECT_ROOT / "scripts" / "xml_to_stream.py"


def find_7z():
    for command in ("7zz", "7z", "7za"):
        found = shutil.which(command)
        if found:
            return found
    raise SystemExit("Install a 7-Zip command line tool on this system.")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--archive", type=Path, required=True)
    parser.add_argument("--site", default="askubuntu.com")
    parser.add_argument("--uri", default="mongodb://127.0.0.1:27017")
    parser.add_argument("--database", default="stackexchange")
    parser.add_argument("--collection", default="posts")
    parser.add_argument("--log", type=Path, default=Path("results/mongodb_import.log"))
    parser.add_argument("--drop-existing", action="store_true", help="drop the target collection before a fresh import")
    args = parser.parse_args()

    mongoimport = shutil.which("mongoimport")
    if not mongoimport:
        raise SystemExit("Install MongoDB Database Tools and ensure mongoimport is on PATH.")
    args.log.parent.mkdir(parents=True, exist_ok=True)
    with args.log.open("wb") as log:
        extractor = subprocess.Popen(
            [find_7z(), "e", "-so", str(args.archive), "Posts.xml"],
            stdout=subprocess.PIPE,
            stderr=log,
        )
        converter = subprocess.Popen(
            [sys.executable, str(CONVERTER), "--site", args.site, "--format", "jsonl"],
            stdin=extractor.stdout,
            stdout=subprocess.PIPE,
            stderr=log,
        )
        extractor.stdout.close()
        command = [
            mongoimport,
            "--uri",
            args.uri,
            "--db",
            args.database,
            "--collection",
            args.collection,
            "--type=json",
            "--mode=insert",
        ]
        if args.drop_existing:
            command.append("--drop")
        importer = subprocess.Popen(
            command,
            stdin=converter.stdout,
            stdout=log,
            stderr=log,
        )
        converter.stdout.close()
        import_status = importer.wait()
        convert_status = converter.wait()
        extract_status = extractor.wait()
    if extract_status or convert_status or import_status:
        raise SystemExit(
            f"Import failed: 7z={extract_status}, converter={convert_status}, "
            f"mongoimport={import_status}. See {args.log}"
        )
    print(f"import complete: {args.database}.{args.collection}")


if __name__ == "__main__":
    main()
