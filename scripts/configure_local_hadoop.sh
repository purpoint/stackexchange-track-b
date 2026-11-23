#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT=$(cd "$(dirname "$0")/.." && pwd)
if [[ -z "$(printenv HADOOP_HOME || true)" ]]; then
  echo "Source /home/cse/.local/opt/bda-hadoop.env first." >&2
  exit 1
fi

cp "$PROJECT_ROOT/cluster/config/core-site.xml" "$HADOOP_HOME/etc/hadoop/core-site.xml"
cp "$PROJECT_ROOT/cluster/config/hdfs-site.xml" "$HADOOP_HOME/etc/hadoop/hdfs-site.xml"
cp "$PROJECT_ROOT/cluster/config/yarn-site.xml" "$HADOOP_HOME/etc/hadoop/yarn-site.xml"
cp "$PROJECT_ROOT/cluster/config/mapred-site.xml" "$HADOOP_HOME/etc/hadoop/mapred-site.xml"
cp "$PROJECT_ROOT/cluster/config/workers" "$HADOOP_HOME/etc/hadoop/workers"
if ! grep -Fq "export JAVA_HOME=$JAVA_HOME" "$HADOOP_HOME/etc/hadoop/hadoop-env.sh"; then
  cat "$PROJECT_ROOT/cluster/config/hadoop-env.sh" >> "$HADOOP_HOME/etc/hadoop/hadoop-env.sh"
fi
echo "Copied the local cluster configuration to $HADOOP_HOME/etc/hadoop."
