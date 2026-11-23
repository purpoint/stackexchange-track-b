#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
source "$ROOT/scripts/project_env.sh"
# Ensure HDFS is writable before setup_hive.sh creates the warehouse.
hdfs dfsadmin -safemode wait
bash "$ROOT/scripts/setup_hive.sh"
export HADOOP_CLASSPATH="$HADOOP_HOME/share/hadoop/common/*:$HADOOP_HOME/share/hadoop/common/lib/*:$HADOOP_HOME/share/hadoop/hdfs/*:$HADOOP_HOME/share/hadoop/hdfs/lib/*:$HADOOP_HOME/share/hadoop/mapreduce/*:$HADOOP_HOME/share/hadoop/mapreduce/lib/*:$HADOOP_HOME/share/hadoop/yarn/*:$HADOOP_HOME/share/hadoop/yarn/lib/*"
exec "$HIVE_HOME/bin/hiveserver2" \
  --hiveconf hive.execution.engine=mr \
  --hiveconf hive.server2.enable.doAs=false \
  --hiveconf hive.aux.jars.path=file:///home/cse/.local/opt/apache-hive-4.1.0-bin/lib/commons-collections-3.2.2.jar \
  --hiveconf hive.metastore.warehouse.dir=/tmp/bda-hive/warehouse
