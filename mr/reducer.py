#!/usr/bin/env python3
"""Sum mapper counts and score totals for each sorted key."""

import sys


def emit(key, count, score_sum, answers_sum):
    if key is not None:
        average = score_sum / count if count else 0
        print(f"{key}\t{count}\t{average:.6f}\t{answers_sum}")


def main():
    current_key = None
    count = 0
    score_sum = 0
    answers_sum = 0
    for line in sys.stdin:
        key, value = line.rstrip("\n").split("\t", 1)
        row_count, row_score, row_answers = value.split(",", 2)
        if current_key is not None and key != current_key:
            emit(current_key, count, score_sum, answers_sum)
            count = 0
            score_sum = 0
            answers_sum = 0
        current_key = key
        count += int(row_count)
        score_sum += int(row_score)
        answers_sum += int(row_answers)
    emit(current_key, count, score_sum, answers_sum)


if __name__ == "__main__":
    main()
