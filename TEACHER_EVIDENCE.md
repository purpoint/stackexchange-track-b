# Track B evidence

All evidence in this folder uses the assigned `askubuntu.com.7z` archive.

## Screenshots

0. `results/teacher_evidence/screenshots/00_assigned_dataset.png` — assigned Ask Ubuntu archive, manifest, source sample, and HDFS input.
1. `results/teacher_evidence/screenshots/01_mongodb_execution.png` — eight MongoDB commands: ping, count, sample document, indexes, aggregation, tags, collection scan, indexed query.
2. `results/teacher_evidence/screenshots/02_hdfs_yarn_cluster.png` — two live HDFS DataNodes and two RUNNING YARN nodes.
3. `results/teacher_evidence/screenshots/03_mapreduce_output.png` — finished YARN job, HDFS `_SUCCESS`, and yearly output.
4. `results/teacher_evidence/screenshots/04_pig_hive_output.png` — successful Pig transformation and Hive TextFile/RCFile comparison.
5. `results/teacher_evidence/screenshots/05_verification_summary.png` — final verification summary.

## Full command output

- MongoDB: `results/teacher_evidence/mongodb_execution.txt`
- HDFS and MapReduce: use the commands in `REAL_CLUSTER_DEMO.md`.
- Pig and Hive: `results/pig/transform.log` and `results/hive/query_comparison.txt`.

The folder also contains final output files ready to open or submit:

- `final_verification_output.txt`
- `hdfs_cluster_report_final.txt`
- `yarn_running_nodes_final.txt`
- `hdfs_input_listing_final.txt`
- `mapreduce_yearly_output_final.tsv`
- `mapreduce_finished_applications_final.txt`
- `mongodb_aggregation_final.json`
- `mongodb_indexes_final.json`
- `mongodb_explain_final.json`
- `pig_execution_final.log`
- `hive_text_vs_rcfile_final.txt`
- `hive_storage_sizes_final.txt`

## Dashboard pages

- NameNode: http://localhost:9870
- DataNodes: http://localhost:9870/dfshealth.html#tab-datanode
- ResourceManager: http://localhost:8088
- YARN applications: http://localhost:8088/cluster/apps
- JobHistory: http://localhost:19888/jobhistory
