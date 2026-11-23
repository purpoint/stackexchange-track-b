#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
if [[ -z "${HADOOP_HOME:-}" || -z "${JAVA_HOME:-}" ]]; then
  echo "Source /home/cse/.local/opt/bda-hadoop.env first." >&2
  exit 1
fi
if [[ ! -f /tmp/bda-hadoop/hdfs/name/current/VERSION ]]; then
  echo "Format the local NameNode once before first startup." >&2
  exit 1
fi
if "$JAVA_HOME/bin/jps" -l | rg -q 'org\.apache\.hadoop\.hdfs\.server\.namenode\.NameNode'; then
  echo "Hadoop services are already running. Run cluster/stop_local_multiworker.sh first." >&2
  exit 1
fi

"$ROOT/scripts/configure_local_hadoop.sh"
python3 "$ROOT/scripts/generate_local_worker_configs.py"

MASTER_PID_DIR=/tmp/bda-hadoop/pids/master
MASTER_LOG_DIR=/tmp/bda-hadoop/logs/master
mkdir -p "$MASTER_PID_DIR" "$MASTER_LOG_DIR"
export HADOOP_CONF_DIR="$HADOOP_HOME/etc/hadoop"
export HADOOP_PID_DIR="$MASTER_PID_DIR"
export HADOOP_LOG_DIR="$MASTER_LOG_DIR"
for pidfile in "$MASTER_PID_DIR"/*.pid; do
  [[ -f "$pidfile" ]] || continue
  if ! kill -0 "$(cat "$pidfile")" 2>/dev/null; then rm -f "$pidfile"; fi
done
"$HADOOP_HOME/bin/hdfs" --daemon start namenode
"$HADOOP_HOME/bin/yarn" --daemon start resourcemanager
"$HADOOP_HOME/bin/mapred" --daemon start historyserver

for index in 1 2 3; do
  WORKER="worker$index"
  PID_DIR="/tmp/bda-hadoop/pids/$WORKER"
  LOG_DIR="/tmp/bda-hadoop/logs/$WORKER"
  mkdir -p "$PID_DIR" "$LOG_DIR" \
    "/tmp/bda-hadoop/workers/$WORKER/hdfs/data" \
    "/tmp/bda-hadoop/workers/$WORKER/yarn/local" \
    "/tmp/bda-hadoop/workers/$WORKER/yarn/logs"
  export HADOOP_CONF_DIR="$ROOT/cluster/worker-configs/$WORKER"
  export HADOOP_PID_DIR="$PID_DIR"
  export HADOOP_LOG_DIR="$LOG_DIR"
  for pidfile in "$PID_DIR"/*.pid; do
    [[ -f "$pidfile" ]] || continue
    if ! kill -0 "$(cat "$pidfile")" 2>/dev/null; then rm -f "$pidfile"; fi
  done
  "$HADOOP_HOME/bin/hdfs" --daemon start datanode
  "$HADOOP_HOME/bin/yarn" --daemon start nodemanager
done

"$JAVA_HOME/bin/jps"
echo "Started three co-located worker processes at 127.0.0.2, .3, and .4."
