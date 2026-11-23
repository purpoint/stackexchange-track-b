#!/usr/bin/env python3
"""Convert a Posts.xml stream to JSON Lines or normalized TSV."""

import argparse
import csv
import json
import re
import sys
import xml.etree.ElementTree as ET
from datetime import datetime

TAG_PATTERN = re.compile(r"<([^<>]+)>")
CAMEL_PATTERN = re.compile(r"(?<!^)(?=[A-Z])")


def snake_case(name):
    return CAMEL_PATTERN.sub("_", name).lower()


def int_value(value):
    if value is None or value == "":
        return None
    try:
        return int(value)
    except ValueError:
        return None


def clean_cell(value):
    if value is None:
        return ""
    return str(value).replace("\t", " ").replace("\r", " ").replace("\n", " ")


def make_record(attributes, site):
    numeric_fields = {
        "id",
        "post_type_id",
        "score",
        "view_count",
        "answer_count",
        "comment_count",
        "owner_user_id",
        "last_editor_user_id",
        "accepted_answer_id",
        "parent_id",
        "favorite_count",
    }
    record = {"site": site}
    for name, value in attributes.items():
        key = snake_case(name)
        record[key] = int_value(value) if key in numeric_fields else value

    post_id = record.get("id")
    record["_id"] = f"{site}:{post_id}" if post_id is not None else f"{site}:missing-id"
    created = record.get("creation_date")
    try:
        record["post_year"] = datetime.fromisoformat(created.replace("Z", "+00:00")).year
    except (AttributeError, ValueError):
        record["post_year"] = None

    raw_tags = record.pop("tags", "") or ""
    if "|" in raw_tags:
        record["tags"] = [tag for tag in raw_tags.split("|") if tag]
    else:
        record["tags"] = TAG_PATTERN.findall(raw_tags)
    return record


def write_json(record):
    sys.stdout.write(json.dumps(record, ensure_ascii=False, separators=(",", ":")) + "\n")


def write_tsv(record, writer):
    values = (
        record.get("site"),
        record.get("id"),
        record.get("post_type_id"),
        record.get("creation_date"),
        record.get("post_year"),
        record.get("score"),
        record.get("view_count"),
        record.get("answer_count"),
        record.get("comment_count"),
        "|".join(record.get("tags") or []),
        record.get("title"),
    )
    writer.writerow([clean_cell(value) for value in values])


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--site", required=True, help="Community archive name, such as askubuntu.com")
    parser.add_argument("--format", choices=("jsonl", "tsv"), required=True)
    args = parser.parse_args()

    writer = None
    if args.format == "tsv":
        writer = csv.writer(
            sys.stdout,
            delimiter="\t",
            quoting=csv.QUOTE_NONE,
            escapechar="\\",
            lineterminator="\n",
        )

    count = 0
    context = ET.iterparse(sys.stdin.buffer, events=("start", "end"))
    _, root = next(context)
    for event, element in context:
        if event == "end" and element.tag.rsplit("}", 1)[-1] == "row":
            record = make_record(element.attrib, args.site)
            if args.format == "jsonl":
                write_json(record)
            else:
                write_tsv(record, writer)
            count += 1
            root.clear()

    print(f"rows={count}", file=sys.stderr)


if __name__ == "__main__":
    main()
