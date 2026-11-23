# Easy teacher demo (one terminal)

Follow these steps in **one Terminal window**, from top to bottom. Copy and paste one command block at a time. Let each command finish before pasting the next block. The Hadoop and Hive jobs can take a little while.

## Cold start after a computer reboot

Use these steps first when Hadoop shows “Connection refused.” This computer's `/tmp` directory was cleared on reboot, so the previous local HDFS files are gone. The project's imported MongoDB data and compressed archive are still saved in this folder.

### 1. Go to the project and load its tools

```bash
cd "/home/cse/Desktop/bda 7 sem assigment/stackexchange_track_b"
source scripts/project_env.sh
```

### 2. Switch MongoDB to the project's saved data

The empty MongoDB service currently listening on port 27017 uses `/home/cse/data/mongodb`. Stop that service through MongoDB (it may report that the shell disconnected as the server shuts down):

```bash
mongosh --quiet admin --eval 'db.shutdownServer()'
```

Start MongoDB against the project's imported database and check its record count:

```bash
mkdir -p results/mongodb
mongod --dbpath "$PWD/data/mongodb" --bind_ip 127.0.0.1 --port 27017 --fork \
  --logpath "$PWD/results/mongodb/mongod.log" --pidfilepath /tmp/bda-mongod.pid
mongosh --quiet stackexchange --eval 'print("Ask Ubuntu posts: " + db.posts.countDocuments({site:"askubuntu.com"}))'
```

Expected count: `945111`. If MongoDB reports an error, stop and keep the error; do not delete `mongod.lock` or WiredTiger files.

### 3. Initialize the fresh HDFS once and start Hadoop

The verified current state has no `/tmp/bda-hadoop/hdfs/name` directory, so the one-time format below is safe for this fresh local HDFS. The conditional skips formatting if that NameNode directory already exists.

```bash
bash scripts/configure_local_hadoop.sh
if [ ! -e /tmp/bda-hadoop/hdfs/name ]; then hdfs namenode -format -nonInteractive; else echo "NameNode directory exists; skipped format."; fi
bash cluster/start_local_multiworker.sh
bash scripts/verify_local_cluster.sh
```

Wait for verification to finish. Expect three live DataNodes, three RUNNING YARN NodeManagers, and a successful sample WordCount. Do not format this NameNode again.

### 4. Restore the normalized dataset to HDFS

The local archive is already downloaded. This streams its Posts.xml member through the converter directly to HDFS; it can take a few minutes and may show little output while running.

```bash
mkdir -p /tmp/stackexchange/raw
set -o pipefail
7z e -so "$PWD/data/archives/askubuntu.com.7z" Posts.xml \
  | python3 scripts/xml_to_stream.py --site askubuntu.com --format tsv \
  | hdfs dfs -put - /tmp/stackexchange/raw/askubuntu.tsv
hdfs dfs -ls -h /tmp/stackexchange/raw
INPUT=/tmp/stackexchange/raw/askubuntu.tsv
```

### 5. Rebuild Pig output and Hive tables

Run Pig to recreate the Hive source folder, then start HiveServer2 and rebuild its tables:

```bash
pig -param INPUT="$INPUT" -param OUTPUT=/tmp/stackexchange/pig_questions -f pig/transform.pig
hdfs dfs -count /tmp/stackexchange/pig_questions
mkdir -p results/hive
nohup bash scripts/start_hiveserver2.sh > results/hive/hiveserver2_console.log 2>&1 < /dev/null &
sleep 30
bash scripts/run_hive_sql.sh -f hive/setup_tables.hql
bash scripts/run_hive_sql.sh -e 'SHOW TABLES IN bda_stackexchange'
```

Wait for each Pig or Hive command to finish; the Hive table setup can take several minutes. Then begin the teacher demonstration at **What to say first** and continue with Sections 1-7. Skip the cold-start steps during a normal demo when services and data are already running.

## One-command full run

After the cold-start setup above is complete, run the full demonstration in one Terminal window:

```bash
bash scripts/run_full_teacher_demo.sh
```

It runs the three assignment themes, checks the cluster, saves a timestamped terminal log under `results/live_demo/`, and leaves Hadoop, MongoDB, and Hive running. It expects the Ask Ubuntu archive and the project's imported MongoDB database to be present.

## Screenshots for the presentation

Open `deliverables/Teacher_Demo_Screenshots/README.md` for a short explanation of the screenshots and what to say about each one. They are still images from the terminal-only demo recording.

## What to say first

> “My project analyzes the Ask Ubuntu dataset from the Stack Exchange data dump. It demonstrates MongoDB document analytics, Hadoop HDFS and MapReduce on YARN, Pig data cleaning, and Hive TextFile versus RCFile queries.”

> “This demo runs on one desktop. It simulates three Hadoop worker processes on that computer. The PDF asks for three separate lab computers, so this local setup demonstrates the software workflows but does not meet that separate-computer requirement.”

## 1. Open the project in Terminal

Paste this block:

```bash
cd "/home/cse/Desktop/bda 7 sem assigment/stackexchange_track_b"
source scripts/project_env.sh
INPUT=/tmp/stackexchange/raw/askubuntu.tsv
pwd
```

The last line should show the `stackexchange_track_b` folder.

## 2. Check that the services are ready

Paste these commands:

```bash
echo "Live HDFS workers:"
hdfs dfsadmin -report | grep -E 'Live datanodes|Name:'
echo "YARN workers:"
yarn node -list -all
echo "MongoDB ping:"
mongosh --quiet --eval 'db.adminCommand({ping:1})'
echo "Ask Ubuntu document count:"
mongosh --quiet stackexchange --eval 'db.posts.countDocuments({site:"askubuntu.com"})'
echo "Hive tables:"
bash scripts/run_hive_sql.sh -e 'SHOW TABLES IN bda_stackexchange'
```

Expected: three live DataNodes, three YARN nodes in `RUNNING` state, MongoDB prints `ok: 1` and document count `945111`, and Hive lists `posts_source`, `posts_text`, and `posts_rc`.

### If Hadoop or YARN is not ready

Run this block once, then repeat the service checks above:

```bash
bash cluster/stop_local_multiworker.sh
bash cluster/start_local_multiworker.sh
bash scripts/verify_local_cluster.sh
```

Do not run `hdfs namenode -format` after the NameNode was initialized; use the cold-start instructions above if this computer rebooted and cleared `/tmp`.

### If MongoDB is not ready

Run this only if the project MongoDB data at `$PWD/data/mongodb` is not already running:

```bash
mkdir -p data/mongodb results/mongodb
mongod --dbpath "$PWD/data/mongodb" --bind_ip 127.0.0.1 --port 27017 --fork \
  --logpath "$PWD/results/mongodb/mongod.log" --pidfilepath /tmp/bda-mongod.pid
```

### If Hive is not ready

Run this only if the Hive `SHOW TABLES` command failed:

```bash
nohup bash scripts/start_hiveserver2.sh > results/hive/hiveserver2_console.log 2>&1 < /dev/null &
sleep 20
bash scripts/run_hive_sql.sh -e 'SHOW TABLES IN bda_stackexchange'
```

## 3. Show the assigned data and MongoDB import

Say:

> “The source is the Ask Ubuntu site archive from Stack Exchange. I imported its post records into MongoDB.”

Show the successful import record and count the loaded documents:

```bash
tail -n 3 results/mongodb/import.log
mongosh --quiet stackexchange --eval 'print("Ask Ubuntu documents: " + db.posts.countDocuments({site:"askubuntu.com"}))'
```

Expected: the log says `945111 document(s) imported successfully`, and the count is `945111`. The import is already done; do not run the importer again during the demo.

## 4. Theme 1 — MongoDB aggregation, indexes, and query profile

Say:

> “MongoDB groups questions by year, summarizes scores and answers, and finds popular tags. I also compare an unindexed scan with the indexed query.”

Run the aggregation:

```bash
mongosh --quiet stackexchange --file mongo/aggregate.js
```

Create/show indexes:

```bash
mongosh --quiet --file mongo/create_indexes.js
```

Show a short live query-performance comparison:

```bash
mongosh --quiet stackexchange --eval '
const posts = db.posts;
const q = {site:"askubuntu.com", post_type_id:1,
  creation_date:{$gte:"2020-01-01T00:00:00.000", $lt:"2021-01-01T00:00:00.000"}};
for (const [label, hint] of [["Collection scan", {$natural:1}], ["Indexed query", "site_type_created"]]) {
  const s = posts.find(q, {_id:0, id:1}).hint(hint).explain("executionStats").executionStats;
  printjson({label, returned:s.nReturned, documentsExamined:s.totalDocsExamined,
    indexKeysExamined:s.totalKeysExamined, timeMs:s.executionTimeMillis});
}'
```

Explain: fewer examined documents/keys means the index can narrow the search. Timings can change between runs.

## 5. Theme 2 — HDFS files and Hadoop Streaming MapReduce on YARN

Say:

> “HDFS stores the input across the Hadoop workers. The first command demonstrates file operations. Then a Python Streaming MapReduce job counts posts by year and runs through YARN.”

Show the HDFS input and run the small file-operation demo:

```bash
hdfs dfs -ls /tmp/stackexchange/raw
bash scripts/demo_hdfs_operations.sh
```

The demo performs HDFS `mkdir`, `put`, `cat`, `get`, and `rm`.

Run the MapReduce job and show its output:

```bash
OUT="/tmp/stackexchange/teacher_mapreduce_$(date +%s)"
bash mr/run_mr.sh "$INPUT" "$OUT"
hdfs dfs -cat "$OUT/part-00000"
yarn application -list -appStates ALL
```

The output has yearly post counts. The YARN command shows submitted/completed jobs.

## 6. Theme 3 — Pig transformation and Hive TextFile/RCFile analytics

Say:

> “Pig filters valid records and keeps questions. Hive stores the transformed rows in two formats, runs the same yearly analysis on both, and lets me compare their results and storage sizes.”

Run Pig and check that its output exists in HDFS:

```bash
PIG_OUT="/tmp/stackexchange/teacher_pig_$(date +%s)"
pig -param INPUT="$INPUT" -param OUTPUT="$PIG_OUT" -f pig/transform.pig
hdfs dfs -count "$PIG_OUT"
```

Run the same Hive query on TextFile and RCFile:

```bash
bash scripts/run_hive_sql.sh --hiveconf hive.execution.engine=mr -f hive/query_text.hql
bash scripts/run_hive_sql.sh --hiveconf hive.execution.engine=mr -f hive/query_rc.hql
```

Show the saved comparison:

```bash
cat results/hive/query_comparison.txt
cat results/hive/storage_sizes.txt
```

The saved run has matching results for both formats and 414,451 question rows. TextFile used 8,494,848 logical bytes; RCFile used 7,239,381. Query times vary, and the saved times are from one run.

## 7. Show the benchmark evidence and final report

```bash
cat results/benchmarks/timings_20261028113213.tsv
xdg-open deliverables/BDA_Track_B_Final_Report.docx
xdg-open deliverables/BDA_Track_B_Presentation_Final.pptx
```

The benchmark file records a one-run comparison with one and two reducers. Present it as a demonstration result, not as a repeated statistical benchmark.

## Quick answers if the teacher asks

- **What does it demonstrate?** Using MongoDB, HDFS, YARN MapReduce, Pig, and Hive to analyze Stack Exchange Ask Ubuntu posts.
- **What does MapReduce calculate?** Post counts by year.
- **What do Pig and Hive do?** Pig cleans and filters records to questions; Hive runs the yearly analysis over TextFile and RCFile tables.
- **What does the MongoDB index comparison show?** How indexes affect the number of documents/keys examined by a query.
- **Is this a physical three-computer cluster?** No. It is a three-worker-process simulation on one desktop; the assignment's separate-lab-computer requirement still needs three physical systems.
