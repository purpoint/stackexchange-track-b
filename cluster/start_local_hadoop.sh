#!/usr/bin/env bash
set -euo pipefail

if [[ -z "$(printenv HADOOP_HOME || true)" ]]; then
  echo "Source /home/cse/.local/opt/bda-hadoop.env first." >&2
  exit 1
fi
NN_VERSION=/tmp/bda-hadoop/hdfs/name/current/VERSION
if [[ ! -f "$NN_VERSION" ]]; then
  echo "HDFS is not formatted. For a new local HDFS only, run: hdfs namenode -format -nonInteractive" >&2
  exit 1
fi

"$HADOOP_HOME/bin/hdfs" --daemon start namenode
"$HADOOP_HOME/bin/hdfs" --daemon start datanode
"$HADOOP_HOME/bin/yarn" --daemon start resourcemanager
"$HADOOP_HOME/bin/yarn" --daemon start nodemanager
"$HADOOP_HOME/bin/mapred" --daemon start historyserver
"$JAVA_HOME/bin/jps"
