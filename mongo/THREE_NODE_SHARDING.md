# MongoDB placement for a three-host lab

The instructor's cluster note says to use one master and two workers. If MongoDB must also distribute data across systems, place a mongos router on the master and one shard on each worker. A small lab can run one-member replica sets for the two shards, while a config server replica set has members on all three hosts. This gives distributed data placement but not shard failover.

Start one config server on each host on port 27019 with replica set name cfgRS, then initialize cfgRS from the master with all three hostnames. Start a shard server on Worker 1 and Worker 2 on port 27018 using replica set names shard1 and shard2. Initialize each one-member set. Start mongos on the master with the config server replica set connection string, then add both worker shards.

Use mongo/init_database.js and mongo/shard_posts.js through mongos. The shard key is the compound site and id pair because post identifiers can overlap between communities. Save sh.status() and the shard collection listing for evidence.

This topology requires several mongod processes and open network ports. The current single-desktop execution plan uses a local MongoDB server, so that run does not prove cross-host sharding.
