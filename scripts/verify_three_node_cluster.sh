#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
RESULTS="$ROOT/results/cluster"
mkdir -p "$RESULTS"
hdfs dfsadmin -report | tee "$RESULTS/three_node_hdfs_report.txt"
yarn node -list -all | tee "$RESULTS/three_node_yarn_nodes.txt"

ACTIVE_DN=$(hdfs dfsadmin -report | awk '/Live datanodes/ {gsub(/[^0-9]/, "", $0); print $0}')
ACTIVE_NM=$(yarn node -list -all | awk -F: '/Total Nodes/ {print $2}')
if (( ACTIVE_DN < 2 || ACTIVE_NM < 2 )); then
  echo "The assignment requires at least two active worker DataNodes and NodeManagers." >&2
  exit 1
fi
echo "Two or more workers are registered. Run the sample YARN job from verify_local_cluster.sh next."
