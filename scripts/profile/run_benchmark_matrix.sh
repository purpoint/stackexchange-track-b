#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/../.." && pwd)
INPUT=$(printenv HDFS_INPUT || true)
PIG_QUESTIONS=$(printenv PIG_QUESTIONS || true)
if [[ -z "$INPUT" || -z "$PIG_QUESTIONS" ]]; then
  echo "Set HDFS_INPUT and PIG_QUESTIONS to HDFS paths first." >&2
  exit 2
fi
RUNS=${RUNS:-3}
REDUCER_SET=${REDUCER_SET:-"1 2"}
SPLIT_SET=${SPLIT_SET:-"67108864 134217728"}
RESULTS="$ROOT/results/benchmarks"
LOGS="$RESULTS/logs"
mkdir -p "$LOGS"
METRICS="$RESULTS/timings_$(date +%Y%m%d%H%M%S).tsv"
if [[ ! -f "$METRICS" ]]; then
  printf 'framework\tsplit_max_bytes\treducers\trepeat\telapsed_s\tuser_cpu_s\tsystem_cpu_s\tmax_rss_kb\tlog\n' > "$METRICS"
fi

run_timed() {
  local framework=$1
  local split_max=$2
  local reducers=$3
  local repeat=$4
  local log=$5
  shift 5
  /usr/bin/time -f '%e\t%U\t%S\t%M' -o "$log.time" "$@" > "$log" 2>&1
  printf '%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$framework" "$split_max" "$reducers" "$repeat" "$(cat "$log.time")" "$log" >> "$METRICS"
}

VMSTAT_LOG="$RESULTS/vmstat_$(date +%Y%m%d%H%M%S).log"
vmstat -w 1 > "$VMSTAT_LOG" &
VMSTAT_PID=$!
trap 'kill "$VMSTAT_PID" 2>/dev/null || true' EXIT

RUN_ID=$(date +%Y%m%d%H%M%S)
for split_max in $SPLIT_SET; do
  for reducers in $REDUCER_SET; do
    repeat=1
    while (( repeat <= RUNS )); do
      suffix="s${split_max}_r${reducers}_n${repeat}"
      mr_out="/tmp/bda-bench/$RUN_ID/mr_$suffix"
      pig_out="/tmp/bda-bench/$RUN_ID/pig_$suffix"
      run_timed "MapReduce" "$split_max" "$reducers" "$repeat" "$LOGS/mr_$suffix.log" \
        env REDUCERS="$reducers" SPLIT_MAXSIZE="$split_max" \
        "$ROOT/mr/run_mr.sh" "$INPUT" "$mr_out"
      run_timed "Pig" "$split_max" "$reducers" "$repeat" "$LOGS/pig_$suffix.log" \
        pig -param INPUT="$PIG_QUESTIONS" -param OUTPUT="$pig_out" \
        -param REDUCERS="$reducers" -param SPLIT_MAXSIZE="$split_max" \
        -f "$ROOT/pig/query.pig"
      run_timed "Hive-Text" "$split_max" "$reducers" "$repeat" "$LOGS/hive_text_$suffix.log" \
        "$ROOT/scripts/run_hive_sql.sh" \
        --hiveconf hive.execution.engine=mr \
        --hiveconf mapreduce.job.reduces="$reducers" \
        --hiveconf mapreduce.input.fileinputformat.split.maxsize="$split_max" \
        -f "$ROOT/hive/query_text.hql"
      run_timed "Hive-RCFile" "$split_max" "$reducers" "$repeat" "$LOGS/hive_rc_$suffix.log" \
        "$ROOT/scripts/run_hive_sql.sh" \
        --hiveconf hive.execution.engine=mr \
        --hiveconf mapreduce.job.reduces="$reducers" \
        --hiveconf mapreduce.input.fileinputformat.split.maxsize="$split_max" \
        -f "$ROOT/hive/query_rc.hql"
      repeat=$((repeat + 1))
    done
  done
done

echo "Raw driver timings: $METRICS"
echo "Whole-host CPU, memory, swap, and block I/O samples: $VMSTAT_LOG"
echo "Each workload log includes the YARN application ID and Hadoop counters."
