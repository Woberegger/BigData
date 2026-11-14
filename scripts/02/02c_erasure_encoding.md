# BigData02 - Erasure Coding (voluntary task)

Task: Configure Erasure Coding on a specific directory after placing some very large files there. <br>
What changes can we find in the required HDD space?<br>
(all actions done as user "hduser")

**IMPORTANT:** This requires at least 3 nodes (in 3 different racks) for this to work!

```bash
su - hduser
```

Create the rack topology script `/usr/local/hadoop/bin/rack-topology.sh` with the following content:<br>
the `getent` command to determine hostname for an IP address is due to the fact that HDFS passes IP addresses only as parameter to check against

```bash
cat >$HADOOP_HOME/bin/rack-topology.sh <<!
#!/bin/bash
MAPFILE=\$HADOOP_CONF_DIR/topology.txt

if [ -f \$MAPFILE ]; then
  while read host rack; do
    # hadoop only interprets IP, so we change the passed IP to a hostname to compare against
    thishost=\$(getent hosts "\$1" | awk '{print \$2}')
    if [[ "\$host" == "\$thishost" ]]; then
      echo "\$rack"
      exit 0
    fi
  done < \$MAPFILE
fi

echo "/dflt-rack"
!
```

As we have used the `getent` command in the script above, we can configure hostnames and do not need to use IP addresses, which might change more regularly.<br>
So we add our own hostname alias "namenode" and the two DataNodes into the mapping file.<br>
(IMPORTANT: in order to work, it is important, that our line in /etc/hosts has "namenode" as first alias)
> e.g. 10.221.54.255   namenode bigdataswd00 # (and not "10.221.54.255   bigdataswd00 namenode")

```bash
MAPFILE=$HADOOP_CONF_DIR/topology.txt
echo "namenode /rack0" >$MAPFILE
echo "datanode1 /rack1" >>$MAPFILE
echo "datanode2 /rack2" >>$MAPFILE

chmod 755 $HADOOP_HOME/bin/rack-topology.sh
```

Insert the following lines into `$HADOOP_CONF_DIR/core-site.xml` (where to find the topology script):

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
```

Find proper policy, which you use for the following placeholder <Policyame>
```bash
hdfs ec -enablePolicy -policy <PolicyName>

hdfs dfs -mkdir /ErasureCoding
hdfs ec -setPolicy -path /ErasureCoding -policy <PolicyName>
```

After placing a large file there (once in a "normal" directory and then in an ErasureCoding directory), view it via the web UI.
You will see replication factor 1 but still each block on all 3 DataNodes.

The growth of used space is somewhat tricky to measure; run the following before and after —
it should only have grown by about 50% of the file size:

```bash
du -d1 /usr/local/hadoop/hadoopdata/hdfs/datanode/
```

as we have configured a very small default block size and ErasureEncodingPolicy requires at least 1MB, we have to pass parameter dfs.blocksize
```bash
hdfs dfs -D dfs.blocksize=1048576 -put Bibel.txt  /ErasureCoding/
```

The following warning can be ignored - it should work nevertheless:

>WARN erasurecode.ErasureCodeNative: Loading ISA-L failed: Failed to load libisal.so.2<br>
> (libisal.so.2: cannot open shared object file: No such file or directory)

check replication factor and blocks in web GUI `http://<NameNodeIP>:9870/explorer.html#/ErasureCoding`