#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
if [[ -z "${HIVE_HOME:-}" || -z "${HADOOP_HOME:-}" ]]; then
  echo "Source scripts/project_env.sh first." >&2
  exit 1
fi
mkdir -p /tmp/bda-hive/warehouse /tmp/bda-hive/scratch
cp "$ROOT/hive/hive-site.xml" "$HIVE_HOME/conf/hive-site.xml"
hdfs dfs -mkdir -p /tmp/bda-hive/warehouse /tmp/bda-hive/scratch
if [[ ! -d /tmp/bda-hive/metastore_db ]]; then
  "$HIVE_HOME/bin/schematool" -dbType derby -initSchema
fi
echo "Hive 4.1.0 configured with embedded Derby metadata and HDFS warehouse /tmp/bda-hive/warehouse."
