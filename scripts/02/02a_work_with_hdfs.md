# BigDate02 - Working with HDFS

The tasks in this file are possible with 1 active datanode, although you will understand better how HDFS works if more than 1
(ideally 3) datanodes are set up. Therefore, if enough time is available, activate additional datanodes beforehand using one of the instructions

**IMPORTANT:** execute all commands as user `hduser` 

```bash
su - hduser
```

To make sure the latest version of the files are available on the platform, as we use them

```bash
cd ~/BigData/
git pull
```

If you have added more datanodes to the `workers` file, you can either run stop-dfs.sh and start-dfs.sh or do what makes more sense in production and add the datanodes at runtime (if you run the "start" without a prior "stop", there will be a warning that some are already running)

```bash
hdfs --workers --daemon stop datanode
hdfs --workers --daemon start datanode
```

After installation and configuration, we want to evaluate where and how HDFS stores the files

See list of commands at [Hadoop FileSystem Shell](https://hadoop.apache.org/docs/stable/hadoop-project-dist/hadoop-common/FileSystemShell.html),
e.g.: `hdfs dfs -ls` (the last commands with '-' prefix are similar to Linux OS commands)

Optionally, you can view files/folders via [](http://namenode:9870/explorer.html#/)

We have connected the HDFS filesystem at the following mount point. Check in between with the following command
whether and on which node it changes after a "put" etc.<br>
**IMPORTANT:** it may be a link, then you must look at the actual directory

```bash
du -d0 /usr/local/hadoop/hadoopdata
```

```bash
hdfs dfs -mkdir -p /user/hduser/testdir
hdfs dfs -ls -R /user/hduser/testdir
```

A good test file that we will also use later for MapReduce examples is the following: either download directly from
the internet as follows, or better from the GitRepo `~/BigData/data/airline_delay_causes.csv`

```bash
hdfs dfs -put -l ~/BigData/data/airline_delay_causes.csv /user/hduser/testdir/
```

Try to activate the trashbin (check which option) and then verify whether the file really lands there

```bash
hdfs dfs -put ~/BigData/data/airline_delay_causes.csv /user/hduser/testdir/copy_to_delete.csv
hdfs dfs -rm -r /user/hduser/testdir/copy_to_delete.csv
hdfs dfs -rm -r -skipTrash /user/hduser/testdir/airline_delay_causes.csv
hdfs dfs -ls -R /user/hduser/.Trash/
```

Look at what happens - are the replicas also kept in the trashbin?

Increase and decrease the replica count with `-setrep` call - what happens? Check via web GUI.
Test with entire directories or individual files

```bash
hdfs dfs -setrep -R 3 /user/hduser
hdfs dfs -setrep -R 2 /user/hduser
```

Try to change the block size for individual files - preferably use a fairly large file where more than 2 blocks are created

```bash
hdfs dfs -D dfs.blocksize=1048576 -put ~/BigData/data/airline_delay_causes.csv /user/hduser/testdir/BlockSize1MB.csv
```

Check which parameter you can use to set when to react to a dead datanode.
Change to 60 seconds - see [HDFS Default Configuration](https://hadoop.apache.org/docs/r3.2.4/hadoop-project-dist/hadoop-hdfs/hdfs-default.xml).<br>
Shut down the assigned process of the 2nd node and see what happens to the replicas of that node after 60 seconds.<br>
When are replicas transferred from one node to another so we have the desired number of 2 again?<br>
Since we all work together on the further nodes, you must find the correct instance by passing the IP of the `namenode` to the grep command

Either:

```bash
kill $(jps -v | grep datanode<IP-Address> | cut -d' ' -f1)
```

Or:

```bash
hdfs --daemon stop datanode
```

Timeout equals to 2 * heartbeat.recheck.interval + 10 * heartbeat.interval. Default for heartbeat.interval is 3 seconds, default for recheck-interval is 300

```bash
export SSH_CLIENT=<NameNode-IP-Address>
source ~/datanode.env
hdfs --daemon start datanode
```

Try `hdfs fsck` and `hdfs dfsadmin` commands

```bash
hdfs fsck  /user/hduser  -files -blocks -replicaDetails
```

Here you can see on which nodes the replicas are located, how many blocks are used, etc.

```bash
hdfs dfsadmin -allowSnapshot|-getDatanodeInfo <NodeName:Port>|-printTopology|-refreshNodes
```

Investigate the purpose of snapshots and try them out - what takes a long time and uses space, creating or first changing a file?

## Additional tasks

1. What could the following error message mean after trying to write to HDFS - when does it occur, what can you do?

```bash
hdfs dfs -put ~/BigData/data/airline_delay_causes.csv /user/hduser/testdir/copy2.csv
```

> Error: `put: Cannot create file/user/hduser/data/airline_delay_causes.csv._COPYING_. Name node is in safe mode.`

2. Optional additional task (for bonus points) see file `02c_erasure_encoding.md`

3. Optional additional task (for bonus points) see file `02d_nfs_mount.md`