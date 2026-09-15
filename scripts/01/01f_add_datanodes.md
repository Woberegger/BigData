# script how to activate additional 2 data nodes

## first we stop our HDFS FS
to be on save side, we do this. In a working cluster environment, add. nodes are added on-the-fly
```bash
stop-yarn.sh
stop-dfs.sh
```

## configure all datanodes
per default this file only contains "localhost", but we want to have 2 more nodes (and use the hostnames)
```bash
cat >$HADOOP_CONF_DIR/workers <<!
namenode
datanode1
datanode2
!
```

## start DFS again
expected output, when an additional data node was started for the first time is the following (in that case for both additional nodes).<br>
Important is the fact, that the paths contain the hostname of the current namenode.
>datanode1: WARNING: /usr/local/hadoop/hadoopdata/datanode10.221.54.255/tmp does not exist. Creating.<br>
>datanode2: WARNING: /usr/local/hadoop/hadoopdata/datanode10.221.54.255/tmp does not exist. Creating.<br>
>datanode1: WARNING: /usr/local/hadoop/logs/datanode10.221.54.255 does not exist. Creating.<br>
>datanode2: WARNING: /usr/local/hadoop/logs/datanode10.221.54.255 does not exist. Creating.<br>

the Web GUI http://\<NameNode-IP\>:9870/dfshealth.html#tab-datanode should now show all 3 datanodes as running.<br>
> **IMPORTANT** We will not use yarn anymore from now on, so no start-yarn.sh needed

```bash
start-dfs.sh
```