# BigData02 - Erasure Coding (voluntary task)

Task: Configure Erasure Coding on a specific directory after placing some very large files there. <br>
What changes can we find in the required HDD space?

**IMPORTANT:** This requires at least 3 nodes (in 3 different racks) for this to work!

Create the rack topology script `/usr/local/hadoop/bin/rack-topology.sh` with the following content:

```bash
cat >$HADOOP_HOME/bin/rack-topology.sh <<!
#!/bin/bash
MAPFILE=\$HADOOP_CONF_DIR/topology.txt

if [ -f \$MAPFILE ]; then
  while read host rack; do
    if [[ "\$host" == "\$1" ]]; then
      echo "\$rack"
      exit 0
    fi
  done < \$MAPFILE
fi

echo "/dflt-rack"
!
```

Apparently only IP addresses work here and not hostnames. So we add our own IP and those of the two DataNodes into the mapping file.

```bash
MAPFILE=$HADOOP_CONF_DIR/topology.txt
echo "$(hostname -I | cut -d' ' -f1) /rack0" >$MAPFILE
echo "10.77.17.48 /rack1" >>$MAPFILE
echo "10.77.18.25 /rack2" >>$MAPFILE
echo "namenode /rack0" >>$MAPFILE
echo "datanode1 /rack1" >>$MAPFILE
echo "datanode2 /rack2" >>$MAPFILE

chmod 755 $HADOOP_HOME/bin/rack-topology.sh
```

Insert the following lines into `core-site.xml` (where to find the topology script):

```vim
   <property>
      <name>net.topology.script.file.name</name>
      <value>/usr/local/hadoop/bin/rack-topology.sh</value>
   </property>
```

Then restart HDFS:

```bash
stop-dfs.sh
start-dfs.sh
```

Print topology:

```bash
hdfs dfsadmin -printTopology
```

Expected output as shown below (IP addresses will vary):

>Rack: /rack0<br>  
>10.77.16.124:9866 (namenode) In Service<br>
><br>
>Rack: /rack1  <br>
>10.77.17.48:50100 (datanode1) In Service<br>
><br>
>Rack: /rack2  <br>
>10.77.18.25:50100 (datanode2) In Service<br>

After that it should be possible to create a new directory and change/check the policy there.

```bash
hdfs ec -listPolicies
hdfs ec -enablePolicy -policy <PolicyName>

hdfs dfs -mkdir /ErasureCoding
hdfs ec -setPolicy -path /ErasureCoding -policy <PolicyName>
```

After placing a large file there (once in a "normal" directory and then in an ErasureCoding directory), view it via the web UI.
You will see replication factor 1 but still each block on all 3 DataNodes.

The growth of used space is somewhat tricky to measure; run the following before and after —
it should only have grown by about 50% of the file size:

```bash
du -d1 /mnt/node1data/
```

The following warning can be ignored - it should work nevertheless:

>WARN erasurecode.ErasureCodeNative: Loading ISA-L failed: Failed to load libisal.so.2<br>
> (libisal.so.2: cannot open shared object file: No such file or directory)