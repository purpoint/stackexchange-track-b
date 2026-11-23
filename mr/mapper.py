#!/usr/bin/env python3
"""Aggregate normalized Stack Exchange records by year and post type."""

import sys


def main():
    for line in sys.stdin:
        fields = line.rstrip("\n").split("\t")
        if len(fields) < 11:
            continue
        site, post_type, year, score = fields[0], fields[2], fields[4], fields[5]
        if not site or post_type != "1" or not year:
            continue
        try:
            numeric_year = int(year)
        except ValueError:
            continue
        if numeric_year < 2015 or numeric_year > 2024:
            continue
        try:
            numeric_score = int(score) if score else 0
        except ValueError:
            numeric_score = 0
        answers = fields[7]
        try:
            numeric_answers = int(answers) if answers else 0
        except ValueError:
            numeric_answers = 0
        print(f"{site}|{year}\t1,{numeric_score},{numeric_answers}")


if __name__ == "__main__":
    main()
