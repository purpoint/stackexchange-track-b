#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "Usage: run_mr.sh HDFS_INPUT HDFS_OUTPUT" >&2
  exit 2
fi
INPUT=$1
OUTPUT=$2
REDUCERS=$(printenv REDUCERS || true)
if [[ -z "$REDUCERS" ]]; then REDUCERS=1; fi
SPLIT_MAXSIZE=$(printenv SPLIT_MAXSIZE || true)
PROJECT_ROOT=$(cd "$(dirname "$0")/.." && pwd)
STREAMING_JAR=$(printenv HADOOP_STREAMING_JAR || true)
if [[ -z "$STREAMING_JAR" ]]; then
  STREAMING_JAR=$(find "$HADOOP_HOME/share/hadoop/tools/lib" -name 'hadoop-streaming-*.jar' -print -quit)
fi
if [[ -z "$STREAMING_JAR" || ! -f "$STREAMING_JAR" ]]; then
  echo "Set HADOOP_STREAMING_JAR or install the Hadoop Streaming jar." >&2
  exit 1
fi

HADOOP_ARGS=(-D mapreduce.job.name=stackexchange-post-counts -D "mapreduce.job.reduces=$REDUCERS")
if [[ -n "$SPLIT_MAXSIZE" ]]; then
  HADOOP_ARGS+=(-D "mapreduce.input.fileinputformat.split.maxsize=$SPLIT_MAXSIZE")
fi

STAGED_FILES=$(mktemp -d /tmp/bda-streaming.XXXXXX)
trap 'rm -rf "$STAGED_FILES"' EXIT
cp "$PROJECT_ROOT/mr/mapper.py" "$PROJECT_ROOT/mr/combiner.py" "$PROJECT_ROOT/mr/reducer.py" "$STAGED_FILES/"

hadoop jar "$STREAMING_JAR" "${HADOOP_ARGS[@]}" \
  -files "$STAGED_FILES/mapper.py,$STAGED_FILES/combiner.py,$STAGED_FILES/reducer.py" \
  -mapper "python3 mapper.py" \
  -combiner "python3 combiner.py" \
  -reducer "python3 reducer.py" \
  -input "$INPUT" \
  -output "$OUTPUT"
