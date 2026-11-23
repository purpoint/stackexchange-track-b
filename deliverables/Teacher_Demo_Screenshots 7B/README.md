# Screenshots for the teacher demo

These are real still frames taken from the 5-minute terminal-only project demonstration recording. The ChatGPT screen is not in these images. Show them in order, or open the recording to demonstrate the commands running.

1. **01_Hadoop_workers_and_YARN_nodes.png** — Shows the three local Hadoop workers and YARN nodes in `RUNNING` state. The workers are three processes on this one desktop.
2. **02_Sample_WordCount_success.png** — Shows the sample Hadoop WordCount job completing. It is the small check that HDFS and YARN work before processing the assignment data.
3. **03_MongoDB_indexes.png** — Shows the MongoDB indexes used by the analytics and query profile.
4. **04_MongoDB_aggregation_results.png** — Shows output from MongoDB aggregation, including popular tags and answer status.
5. **05_MapReduce_yearly_results.png** — Shows the Python Streaming MapReduce results grouped by year.
6. **06_Pig_transformation_success.png** — Shows Pig reading 945,111 input records and writing 414,451 question records after transformation.
7. **07_Hive_TextFile_vs_RCFile_comparison.png** — Shows Hive comparison output. Both tables returned the same 10 years. In this single run, TextFile query time was 35.28 seconds and RCFile was 38.11 seconds; RCFile's logical file size was smaller (7,239,381 vs. 8,494,848 bytes). Treat the times as a one-run demonstration, not a repeated benchmark.
8. **08_Final_success_and_Hive_tables.png** — Shows the final Hive table names and the `DEMO COMPLETE` message.

Simple explanation to tell your teacher: “The project processes the Ask Ubuntu Stack Exchange posts using MongoDB, Hadoop MapReduce, Pig, and Hive. This screen evidence shows each stage ran. My Hadoop workers are simulated as three processes on one desktop, so this does not meet the PDF's three-separate-computers requirement.”
