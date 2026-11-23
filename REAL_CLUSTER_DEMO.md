# Real two-node Stack Exchange demonstration

This run uses only `data/archives/askubuntu.com.7z` from the assigned Stack Exchange archive.
The master is `172.16.6.150` and the worker is `172.16.4.91` (`worker1`).

## Master terminal

```bash
cd "/home/cse/Desktop/bda 7 sem assigment/stackexchange_track_b"
source scripts/project_env.sh
hdfs dfsadmin -report
yarn node -list -all
hdfs dfs -ls /user/cse/stackexchange/posts_tsv
hdfs dfs -ls /user/cse/stackexchange/results/post_counts_final
hdfs dfs -cat /user/cse/stackexchange/results/post_counts_final/part-*
```

The expected evidence is two live HDFS DataNodes, two RUNNING YARN nodes, the Ask Ubuntu TSV, `_SUCCESS`, and ten yearly result rows.

## Web pages to show

- NameNode: `http://localhost:9870`
- NameNode DataNodes: `http://localhost:9870/dfshealth.html#tab-datanode`
- ResourceManager: `http://localhost:8088`
- YARN applications: `http://localhost:8088/cluster/apps`
- JobHistory: `http://localhost:19888/jobhistory`

## What to explain

The 7-Zip archive is streamed through `scripts/xml_to_stream.py` into HDFS. Hadoop splits the TSV into two map tasks, runs Python streaming mapper/combiner/reducer processes through YARN, and writes the final yearly question counts, average scores, and answer totals to HDFS. The live DataNode and NodeManager registrations prove that the work used the master and worker machines.

The PDF asks for at least three lab systems; this demonstration has one master and one worker because that is the topology selected for this run.
