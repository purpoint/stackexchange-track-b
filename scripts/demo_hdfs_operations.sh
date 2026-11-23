#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
DEMO_ROOT="/tmp/bda-hdfs-demo-$(date +%Y%m%d%H%M%S)"
LOCAL_COPY="$ROOT/results/hdfs_demo_sample.txt"
mkdir -p "$ROOT/results"
LOCAL_INPUT=$(mktemp /tmp/bda-hdfs-input.XXXXXX)
LOCAL_DOWNLOAD_DIR=$(mktemp -d /tmp/bda-hdfs-download.XXXXXX)
LOCAL_DOWNLOAD="$LOCAL_DOWNLOAD_DIR/sample.txt"
trap 'rm -f "$LOCAL_INPUT"; rm -rf "$LOCAL_DOWNLOAD_DIR"' EXIT
printf 'Stack Exchange HDFS demo row one\nStack Exchange HDFS demo row two\n' > "$LOCAL_INPUT"
hdfs dfs -mkdir -p "$DEMO_ROOT/input"
hdfs dfs -put "$LOCAL_INPUT" "$DEMO_ROOT/input/sample.txt"
hdfs dfs -cat "$DEMO_ROOT/input/sample.txt"
hdfs dfs -get "$DEMO_ROOT/input/sample.txt" "$LOCAL_DOWNLOAD"
cmp "$LOCAL_INPUT" "$LOCAL_DOWNLOAD"
cp "$LOCAL_DOWNLOAD" "$LOCAL_COPY"
hdfs dfs -rm -r "$DEMO_ROOT"
echo "HDFS mkdir, put, cat, get, and rm -r completed. Local evidence copy: $LOCAL_COPY"
