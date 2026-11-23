#!/usr/bin/env bash
set -Eeuo pipefail
PROJECT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
cd "$PROJECT_DIR"
source scripts/project_env.sh

mkdir -p results/live_demo results/mongodb results/hive
LOG="results/live_demo/teacher_demo_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee "$LOG") 2>&1

echo "Track B live demo started at $(date -Is)"
echo "Project directory: $PWD"
echo "Terminal log: $LOG"

echo "Step 1: Stop the unrelated empty MongoDB service, if it is running."
mongosh --quiet admin --eval 'db.shutdownServer()' || true
sleep 2

echo "Step 2: Start MongoDB using the project's saved database."
if ! pgrep -af "mongod --dbpath $PWD/data/mongodb" | grep -v "pgrep -af" >/dev/null; then
  mongod --dbpath "$PWD/data/mongodb" --bind_ip 127.0.0.1 --port 27017 --fork \
    --logpath "$PWD/results/mongodb/mongod.log" --pidfilepath /tmp/bda-mongod.pid
fi
mongo_count=$(mongosh --quiet stackexchange --eval 'db.posts.countDocuments({site:"askubuntu.com"})')
echo "Ask Ubuntu documents in project database: $mongo_count"
if [[ "$mongo_count" != "945111" ]]; then
  echo "Expected 945111 existing MongoDB documents. Stopping to avoid reimporting or overwriting the saved database." >&2
  exit 1
fi

echo "Step 3: Configure Hadoop and initialize NameNode only if the local NameNode directory is absent."
bash scripts/configure_local_hadoop.sh
if "$JAVA_HOME/bin/jps" -l | grep -q 'org.apache.hadoop.hdfs.server.namenode.NameNode'; then
  echo "Hadoop cluster is already running; skipped format and startup."
else
  if [[ ! -e /tmp/bda-hadoop/hdfs/name ]]; then
    hdfs namenode -format -nonInteractive
  elif [[ ! -f /tmp/bda-hadoop/hdfs/name/current/VERSION ]]; then
    echo "NameNode directory exists but has no VERSION file. Refusing to format existing storage." >&2
    exit 1
  else
    echo "Existing NameNode metadata found; skipped format."
  fi
  bash cluster/start_local_multiworker.sh
fi

echo "Step 4: Verify HDFS, YARN, three local workers, and sample WordCount."
bash scripts/verify_local_cluster.sh

echo "Step 5: Stream the assigned Archive.org Posts.xml into HDFS."
echo "This streams the uncompressed XML member; please wait for the command to return."
hdfs dfs -mkdir -p /tmp/stackexchange/raw
hdfs dfs -rm -f /tmp/stackexchange/raw/askubuntu.tsv >/dev/null 2>&1 || true
7z e -so "$PWD/data/archives/askubuntu.com.7z" Posts.xml \
  | python3 scripts/xml_to_stream.py --site askubuntu.com --format tsv \
  | hdfs dfs -put - /tmp/stackexchange/raw/askubuntu.tsv
INPUT=/tmp/stackexchange/raw/askubuntu.tsv
hdfs dfs -ls -h /tmp/stackexchange/raw

echo "Step 6: Theme 1 - MongoDB indexes, aggregation, and query executionStats."
mongosh --quiet --file mongo/create_indexes.js
mongosh --quiet stackexchange --file mongo/aggregate.js
mongosh --quiet stackexchange --file mongo/explain_index_compare.js

echo "Step 7: Theme 2 - HDFS file operations and Python Streaming MapReduce on YARN."
bash scripts/demo_hdfs_operations.sh
OUT="/tmp/stackexchange/teacher_mapreduce_$(date +%s)"
bash mr/run_mr.sh "$INPUT" "$OUT"
echo "MapReduce yearly results:"
hdfs dfs -cat "$OUT/part-00000"
echo "YARN applications:"
yarn application -list -appStates ALL

echo "Step 8: Theme 3 - Pig transformation on YARN."
PIG_OUT=/tmp/stackexchange/pig_questions
hdfs dfs -rm -r -f "$PIG_OUT" >/dev/null 2>&1 || true
pig -param INPUT="$INPUT" -param OUTPUT="$PIG_OUT" -f pig/transform.pig
hdfs dfs -count "$PIG_OUT"

echo "Step 9: Start HiveServer2 and wait for its TCP port."
if ! jps -l | grep -q 'org.apache.hive.service.server.HiveServer2'; then
  nohup bash scripts/start_hiveserver2.sh > results/hive/hiveserver2_console.log 2>&1 < /dev/null &
fi
ready=0
for attempt in $(seq 1 60); do
  if (echo > /dev/tcp/127.0.0.1/10000) >/dev/null 2>&1; then ready=1; break; fi
  sleep 2
done
if [[ "$ready" != 1 ]]; then
  echo "HiveServer2 did not open port 10000. Recent HiveServer2 log:" >&2
  tail -n 80 results/hive/hiveserver2_console.log >&2
  exit 1
fi

echo "Step 10: Create Hive tables and compare TextFile and RCFile queries."
bash scripts/run_hive_sql.sh -f hive/setup_tables.hql
bash scripts/run_hive_sql.sh -e 'SHOW TABLES IN bda_stackexchange'
bash scripts/run_hive_sql.sh --hiveconf hive.execution.engine=mr -f hive/query_text.hql
bash scripts/run_hive_sql.sh --hiveconf hive.execution.engine=mr -f hive/query_rc.hql
cat results/hive/query_comparison.txt
cat results/hive/storage_sizes.txt

echo "Step 11: Show the Track B profiling matrix and final report/presentation files."
latest_benchmark=$(find results/benchmarks -maxdepth 1 -name 'timings_*.tsv' -type f -printf '%T@ %p\n' | sort -nr | head -n 1 | cut -d' ' -f2-)
cat "$latest_benchmark"
ls -lh deliverables/BDA_Track_B_Final_Report.docx deliverables/BDA_Track_B_Presentation_Final.pptx

echo "Final checks:"
hdfs dfsadmin -report | grep -E 'Live datanodes|Name:'
yarn node -list -all
mongosh --quiet stackexchange --eval 'print("Ask Ubuntu posts: " + db.posts.countDocuments({site:"askubuntu.com"}))'
bash scripts/run_hive_sql.sh -e 'SHOW TABLES IN bda_stackexchange'
echo "DEMO COMPLETE at $(date -Is). Hadoop, MongoDB, and HiveServer2 are left running for the teacher demonstration."
