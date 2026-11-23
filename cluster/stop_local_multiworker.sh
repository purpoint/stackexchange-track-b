#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
if [[ -z "${HADOOP_HOME:-}" || -z "${JAVA_HOME:-}" ]]; then
  echo "Source /home/cse/.local/opt/bda-hadoop.env first." >&2
  exit 1
fi

for index in 3 2 1; do
  WORKER="worker$index"
  export HADOOP_CONF_DIR="$ROOT/cluster/worker-configs/$WORKER"
  export HADOOP_PID_DIR="/tmp/bda-hadoop/pids/$WORKER"
  export HADOOP_LOG_DIR="/tmp/bda-hadoop/logs/$WORKER"
  "$HADOOP_HOME/bin/yarn" --daemon stop nodemanager || true
  "$HADOOP_HOME/bin/hdfs" --daemon stop datanode || true
done

export HADOOP_CONF_DIR="$HADOOP_HOME/etc/hadoop"
export HADOOP_PID_DIR=/tmp/bda-hadoop/pids/master
export HADOOP_LOG_DIR=/tmp/bda-hadoop/logs/master
"$HADOOP_HOME/bin/mapred" --daemon stop historyserver || true
"$HADOOP_HOME/bin/yarn" --daemon stop resourcemanager || true
"$HADOOP_HOME/bin/hdfs" --daemon stop namenode || true
echo "Stopped the local multiworker simulation."
