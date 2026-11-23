#!/usr/bin/env python3
"""Stream a .7z Posts.xml file through the converter and into HDFS."""

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
    parser.add_argument("--hdfs-dir", default="/tmp/stackexchange/posts_tsv")
    parser.add_argument("--logs", type=Path, default=Path("results/ingest"))
    args = parser.parse_args()
    hdfs = shutil.which("hdfs")
    if not hdfs:
        raise SystemExit("Hadoop is not on PATH. Source the project Hadoop environment file.")

    seven_zip = find_7z()
    args.logs.mkdir(parents=True, exist_ok=True)
    target = args.hdfs_dir.rstrip("/") + "/" + args.site + ".tsv"
    log_path = args.logs / f"{args.site}.log"
    subprocess.run([hdfs, "dfs", "-mkdir", "-p", args.hdfs_dir], check=True)
    with log_path.open("wb") as log:
        extractor = subprocess.Popen(
            [seven_zip, "e", "-so", str(args.archive), "Posts.xml"],
            stdout=subprocess.PIPE,
            stderr=log,
        )
        converter = subprocess.Popen(
            [sys.executable, str(CONVERTER), "--site", args.site, "--format", "tsv"],
            stdin=extractor.stdout,
            stdout=subprocess.PIPE,
            stderr=log,
        )
        extractor.stdout.close()
        uploader = subprocess.Popen(
            [hdfs, "dfs", "-put", "-f", "-", target],
            stdin=converter.stdout,
            stderr=log,
        )
        converter.stdout.close()
        upload_status = uploader.wait()
        convert_status = converter.wait()
        extract_status = extractor.wait()
    if extract_status or convert_status or upload_status:
        raise SystemExit(
            f"Pipeline failed: 7z={extract_status}, converter={convert_status}, "
            f"HDFS put={upload_status}. See {log_path}"
        )
    print(f"created={target}")


if __name__ == "__main__":
    main()
