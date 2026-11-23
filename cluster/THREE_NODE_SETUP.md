# Three-host Hadoop cluster requirement

The assignment instruction requires at least three physical lab systems on the same network. This local project uses one desktop at the user's latest request, so the configuration in cluster/config is a one-host configuration and does not meet that requirement.

For the required lab cluster, use one master and two workers. Give every host a stable hostname and IP, verify bidirectional name resolution and SSH, install the same stable Hadoop build and a compatible Java release, and distribute an identical Hadoop configuration to every node.

## Roles

- Master: NameNode and ResourceManager. A SecondaryNameNode or JobHistory server may run here if resources permit.
- Worker 1 and Worker 2: DataNode and NodeManager.
- All three hosts: same Hadoop version, compatible Java, shared host resolution, working SSH for the Hadoop operator.

## Required site configuration

Configure core-site.xml with fs.defaultFS pointing to the master NameNode RPC address.
Configure hdfs-site.xml with local NameNode and DataNode storage paths, directory ownership, and replication factor 2 for two workers.
Configure yarn-site.xml with the master ResourceManager host, mapreduce_shuffle, and container resources based on the actual lab RAM.
Configure mapred-site.xml with mapreduce.framework.name set to yarn and the JobHistory server address if enabled.
List Worker 1 and Worker 2, one hostname per line, in etc/hadoop/workers. This file supports Hadoop's helper scripts; it does not replace Hadoop service configuration.
Set JAVA_HOME in hadoop-env.sh on every node.

## Start sequence

Create the storage directories on the correct host and assign them to the Hadoop service account. Confirm that Hadoop configuration is identical on all systems. Format a fresh NameNode once only, then start HDFS and YARN. Do not format an existing NameNode directory.

Check hdfs dfsadmin -report and yarn node -list -all. Both workers must appear live. Then run the Hadoop examples WordCount job with input in HDFS and capture its YARN application ID and output. Save the browser evidence from the NameNode and ResourceManager web interfaces.

The official guide describes the cluster roles, Java configuration, site XML files, workers list, SSH trust for helper scripts, and HDFS/YARN startup: https://apache.github.io/hadoop/hadoop-project-dist/hadoop-common/ClusterSetup.html

