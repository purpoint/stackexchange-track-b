# Track B execution and demo checklist

## Scope

The local evidence uses only the assigned Archive.org Stack Exchange Data Dump, specifically `askubuntu.com.7z`. The full Stack Exchange community collection does not fit the available disk. This execution uses one physical desktop with three co-located DataNode and NodeManager processes; it cannot satisfy the separate requirement for at least three college lab computers. `cluster/THREE_NODE_SETUP.md` has the actual multi-computer setup procedure.

## Local cluster verification

```bash
source scripts/project_env.sh
bash cluster/start_local_multiworker.sh
bash scripts/verify_local_cluster.sh
bash scripts/demo_hdfs_operations.sh
```

Confirm the verification log reports 3 DataNodes and 3 RUNNING YARN NodeManagers. The verification script also submits sample WordCount to YARN. The NameNode data is under `/tmp/bda-hadoop`; format it only for a new empty local cluster, never when retaining HDFS data.

## Dataset

```bash
source scripts/project_env.sh
python3 scripts/prepare_hdfs.py --archive data/archives/askubuntu.com.7z --site askubuntu.com --hdfs-dir /tmp/stackexchange/raw
python3 scripts/analyze_tsv.py /tmp/stackexchange/raw/askubuntu.com.tsv --output results/dataset
python3 scripts/import_mongodb.py --archive data/archives/askubuntu.com.7z --site askubuntu.com --drop-existing --log results/mongodb/import.log
```

The downloaded file, source URL, byte size, retrieval date, and SHA-256 are recorded in `data/archives/MANIFEST-askubuntu.json`. The converter streams the XML member and parses pipe-delimited tags.

## Theme 1 — MongoDB

```bash
mongosh stackexchange --file mongo/create_indexes.js > results/mongodb/indexes.json
mongosh stackexchange --file mongo/aggregate.js > results/mongodb/aggregations.json
mongosh stackexchange --file mongo/explain_index_compare.js > results/mongodb/explain.json
```

Capture collection count and storage with `db.posts.stats()`. The explain comparison forces a collection scan and compares it to the compound `(site, post_type_id, creation_date)` index. Results are specific to this dataset and run.

## Theme 2 — HDFS and MapReduce

```bash
bash mr/run_mr.sh /tmp/stackexchange/raw/askubuntu.com.tsv /tmp/stackexchange/yearly
hdfs dfs -cat /tmp/stackexchange/yearly/part-00000 > results/mapreduce/yearly.tsv
```

The MapReduce mapper emits count, score sum, and reported answer sum; the combiner only sums these values; the reducer computes mean score. Save the YARN job log, application state and counters. The HDFS demo script covers mkdir, put, ls, cat, get and rm -r.

## Theme 3 — Pig and Hive

```bash
source scripts/project_env.sh
pig -param INPUT=/tmp/stackexchange/raw/askubuntu.com.tsv \
    -param OUTPUT=/tmp/stackexchange/pig_questions \
    -f pig/transform.pig
```

Start HiveServer2 in its own terminal after HDFS leaves safe mode:

```bash
bash scripts/start_hiveserver2.sh
```

In another terminal, load both storage formats and run the paired queries:

```bash
bash scripts/run_hive_sql.sh --hiveconf hive.execution.engine=mr -f hive/setup_tables.hql
bash scripts/run_hive_sql.sh --hiveconf hive.execution.engine=mr -f hive/query_text.hql
bash scripts/run_hive_sql.sh --hiveconf hive.execution.engine=mr -f hive/query_rc.hql
hdfs dfs -du -h /tmp/bda-hive/warehouse/bda_stackexchange.db/posts_text
hdfs dfs -du -h /tmp/bda-hive/warehouse/bda_stackexchange.db/posts_rc
```

Hive 4.1.0 uses a MapReduce execution setting here. The Hive 3.x-era task dependency `commons-collections-3.2.2.jar` is added to the MapReduce application classpath in `cluster/config/mapred-site.xml` and `hive/hive-site.xml` so YARN containers can load it. Save the table counts, same-query outputs, sizes, application IDs, and `/usr/bin/time -v` outputs.

## Track B Part 2 performance extension

```bash
source scripts/project_env.sh
HDFS_INPUT=/tmp/stackexchange/raw/askubuntu.com.tsv \
PIG_QUESTIONS=/tmp/stackexchange/pig_questions \
RUNS=1 REDUCER_SET="1 2" SPLIT_SET="67108864" \
bash scripts/profile/run_benchmark_matrix.sh
```

The runner records MapReduce, Pig, Hive Text and Hive RCFile timings, YARN logs, reducer settings, maximum RSS, and whole-host `vmstat`. A coursework quality run should use three repetitions, both split limits and the physical lab cluster; the quick local matrix is a demonstration and should be labeled as single-host profiling.

## Demo order

1. Dataset manifest and dataset summary.
2. HDFS report, active YARN nodes, successful WordCount.
3. MongoDB aggregation and query explain comparison.
4. HDFS operations and yearly MapReduce output.
5. Pig transformation output and Hive Text/RCFile query and storage evidence.
6. Track B performance extension and the single-host constraint.
