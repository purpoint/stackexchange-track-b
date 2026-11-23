#!/usr/bin/env bash
set -euo pipefail

"$HADOOP_HOME/bin/mapred" --daemon stop historyserver
"$HADOOP_HOME/bin/yarn" --daemon stop nodemanager
"$HADOOP_HOME/bin/yarn" --daemon stop resourcemanager
"$HADOOP_HOME/bin/hdfs" --daemon stop datanode
"$HADOOP_HOME/bin/hdfs" --daemon stop namenode
