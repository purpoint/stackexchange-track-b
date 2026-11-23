#!/usr/bin/env python3
"""Summarize the normalized Stack Exchange TSV stream from HDFS."""

import argparse
import csv
import json
import subprocess
from collections import Counter
from pathlib import Path
from io import TextIOWrapper


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("hdfs_path", help="HDFS file or directory containing normalized TSV")
    parser.add_argument("--output", type=Path, default=Path("results/dataset"))
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=True)

    stream = subprocess.Popen(["hdfs", "dfs", "-cat", args.hdfs_path], stdout=subprocess.PIPE)
    assert stream.stdout is not None
    rows = TextIOWrapper(stream.stdout, encoding="utf-8", errors="replace", newline="")
    total = 0
    post_types = Counter()
    years = Counter()
    tags = Counter()
    date_min = None
    date_max = None
    for row in csv.reader(rows, delimiter="\t", escapechar="\\"):
        if len(row) < 11:
            continue
        total += 1
        post_type = row[2]
        post_types[post_type] += 1
        try:
            year = int(row[4])
            years[year] += 1
        except ValueError:
            pass
        for tag in filter(None, row[9].split("|")):
            tags[tag] += 1
        created = row[3]
        if created:
            date_min = created if date_min is None or created < date_min else date_min
            date_max = created if date_max is None or created > date_max else date_max
    rows.close()
    status = stream.wait()
    if status:
        raise SystemExit(f"hdfs dfs -cat failed with exit code {status}")

    summary = {
        "hdfs_path": args.hdfs_path,
        "total_posts": total,
        "questions_post_type_1": post_types["1"],
        "answers_post_type_2": post_types["2"],
        "other_post_types": {key: count for key, count in sorted(post_types.items()) if key not in {"1", "2"}},
        "first_creation_date": date_min,
        "last_creation_date": date_max,
        "retrieved_snapshot": "2024-04 Stack Exchange dump release",
    }
    (args.output / "summary.json").write_text(json.dumps(summary, indent=2) + "\n", encoding="utf-8")
    with (args.output / "posts_by_year.csv").open("w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        writer.writerow(["year", "posts"])
        writer.writerows(sorted(years.items()))
    with (args.output / "top_tags.csv").open("w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        writer.writerow(["tag", "post_count"])
        writer.writerows(tags.most_common(25))
    print(json.dumps(summary, indent=2))


if __name__ == "__main__":
    main()
