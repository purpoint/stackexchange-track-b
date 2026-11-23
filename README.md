# BCS714D Big Data Analytics — Track B

This project implements the three Track B themes on the assigned Stack Exchange Data Dump. The selected dataset is the Archive.org Ask Ubuntu community archive; it is a documented slice of the Stack Exchange dump rather than the full multi-community corpus.

## Execution scope

The local run uses OpenJDK 17.0.20.1, Hadoop 3.5.0, MongoDB 7.0.11, Pig 0.18.0, and Hive 4.1.0. Hadoop runs one master plus three co-located DataNode/NodeManager processes on this desktop, with addresses 127.0.0.2–127.0.0.4. HDFS, YARN, sample WordCount, MapReduce, Pig, and Hive jobs were run locally.

The assignment specifies at least three distinct lab computers on a shared network. The desktop simulation does not meet that physical-host requirement. The separate-host procedure is in `cluster/THREE_NODE_SETUP.md`; the report and presentation label the local limitation explicitly.

## Track B deliverables

1. **MongoDB analytics:** streamed Posts.xml ingestion, compound and multikey indexes, yearly/tag/answer-status aggregations, and collection-scan versus indexed explain statistics.
2. **HDFS and MapReduce:** HDFS mkdir/put/cat/get/rm operations and a Python Streaming aggregation submitted through YARN.
3. **Pig and Hive:** Pig filtering and schema cleanup, Hive TextFile and RCFile tables, equivalent yearly queries, and storage/runtime evidence.
4. **Part 2 performance extension:** profiling artifacts and captured measurements for MongoDB, Pig, MapReduce, and Hive. `scripts/profile/run_benchmark_matrix.sh` varies split size and reducer count for repeatable lab runs. A quick one-pass 64 MiB comparison with one and two reducers has been captured for MapReduce, Pig, Hive Text and Hive RCFile; see `results/benchmarks/`.
5. **Submission materials:** final report and presentation are in `deliverables/`; logs and output evidence are under `results/`.

## Fast local run

Open a terminal in this directory:

```bash
source scripts/project_env.sh
bash cluster/start_local_multiworker.sh
bash scripts/verify_local_cluster.sh
bash scripts/demo_hdfs_operations.sh
```

The archive manifest is `data/archives/MANIFEST-askubuntu.json`. After extracting/converting the archive, MongoDB import is:

```bash
python3 scripts/import_mongodb.py --archive data/archives/askubuntu.com.7z --site askubuntu.com --drop-existing
mongosh stackexchange --file mongo/create_indexes.js
mongosh stackexchange --file mongo/aggregate.js
mongosh stackexchange --file mongo/explain_index_compare.js
```

HDFS and YARN job entry points are `mr/run_mr.sh` and `pig/transform.pig`. Hive server setup and SQL are described in `scripts/setup_hive.sh`, `hive/setup_tables.hql`, and `scripts/run_hive_sql.sh`. Source `scripts/project_env.sh` in each terminal. The Hive configuration ships the required Commons Collections jar to MapReduce workers.

## Results and evidence

- `results/cluster/`: HDFS DataNode report, YARN node list, sample WordCount application and output.
- `results/dataset/`: record counts, post years, top tags and source sample.
- `results/mongodb/`: import log, indexes, aggregation, explain plans and collection statistics.
- `results/mapreduce/`: YARN log, counters and yearly output.
- `results/pig/`: transformation output counts, YARN log and timing.
- `results/hive/`: table setup, query outputs, table sizes and run timings.
- `results/benchmarks/`: repeatable split/reducer matrix outputs when run.

The complete archive remains at `data/archives/askubuntu.com.7z`; it is not duplicated in the compact submission bundle because it is about 1 GiB.
