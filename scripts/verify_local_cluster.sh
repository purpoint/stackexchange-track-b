#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
RESULTS="$ROOT/results/cluster"
mkdir -p "$RESULTS"

EXPECTED_WORKERS=${EXPECTED_WORKERS:-3}

for attempt in $(seq 1 30); do
  ACTIVE_DN=$(hdfs dfsadmin -report 2>/dev/null | awk -F'[()]' '/Live datanodes/ {print $2; exit}')
  ACTIVE_NM=$(yarn node -list -all 2>/dev/null | awk -F: '/Total Nodes/ {gsub(/[^0-9]/, "", $2); print $2; exit}')
  if [[ "${ACTIVE_DN:-0}" -ge "$EXPECTED_WORKERS" && "${ACTIVE_NM:-0}" -ge "$EXPECTED_WORKERS" ]]; then
    break
  fi
  sleep 2
done

hdfs dfsadmin -safemode wait

{
  date -Is
  java -version 2>&1
  hadoop version
  hdfs dfsadmin -report
} | tee "$RESULTS/local_hdfs_report.txt"
yarn node -list -all | tee "$RESULTS/local_yarn_nodes.txt"

ACTIVE_DN=$(hdfs dfsadmin -report | awk -F'[()]' '/Live datanodes/ {print $2; exit}')
ACTIVE_NM=$(yarn node -list -all | awk -F: '/Total Nodes/ {gsub(/[^0-9]/, "", $2); print $2; exit}')
if (( ACTIVE_DN < EXPECTED_WORKERS )); then
  echo "Expected $EXPECTED_WORKERS live DataNodes, found $ACTIVE_DN." >&2
  exit 1
fi
if (( ACTIVE_NM < EXPECTED_WORKERS )); then
  echo "Expected $EXPECTED_WORKERS YARN NodeManagers, found $ACTIVE_NM." >&2
  exit 1
fi

EXAMPLES_JAR=$(find "$HADOOP_HOME/share/hadoop/mapreduce" -maxdepth 1 -type f -name 'hadoop-mapreduce-examples-*.jar' -print -quit)
if [[ -z "$EXAMPLES_JAR" ]]; then
  echo "Hadoop MapReduce examples jar not found." >&2
  exit 1
fi

RUN_ID=$(date +%Y%m%d%H%M%S)
LOCAL_INPUT=$(mktemp -d)
trap 'rm -rf "$LOCAL_INPUT"' EXIT
printf 'hadoop distributed smoke test node one\n' > "$LOCAL_INPUT/one.txt"
printf 'hadoop cluster verification node two\n' > "$LOCAL_INPUT/two.txt"
printf 'three worker distributed test node three\n' > "$LOCAL_INPUT/three.txt"
hdfs dfs -mkdir -p "/tmp/bda-smoke/$RUN_ID/input"
hdfs dfs -put "$LOCAL_INPUT"/*.txt "/tmp/bda-smoke/$RUN_ID/input/"
hadoop jar "$EXAMPLES_JAR" wordcount \
  "/tmp/bda-smoke/$RUN_ID/input" \
  "/tmp/bda-smoke/$RUN_ID/output" | tee "$RESULTS/local_wordcount.log"
hdfs dfs -cat "/tmp/bda-smoke/$RUN_ID/output/part-r-00000" | tee "$RESULTS/local_wordcount_output.txt"
yarn application -list -appStates ALL | tee "$RESULTS/local_yarn_applications.txt"
echo "Verification completed with $ACTIVE_DN co-located DataNodes and $ACTIVE_NM co-located NodeManagers."
