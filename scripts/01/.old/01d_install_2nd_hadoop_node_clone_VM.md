# BigData01 - set up 2nd Hadoop node by cloning VM

## Guide to set up a 2nd or 3rd node to serve as pure DataNodes (i.e. worker nodes)

In VirtualBox/VMware it's best to create a snapshot and clone (linked clone to save space) and then create an internal network with fixed IPs.  
This guide describes setting up a 2nd node with the hostname `UbuntuBigDataNode1`.

**IMPORTANT:** On this node only the `DataNode` and `NodeManager` processes should run;
they are started from the PRIMARY node via `start-dfs.sh` and `start-yarn.sh`.
Do not start those processes on the cloned nodes (remove autostart scripts if present).

On DataNode: we must assign a different hostname - calling `hostname` alone is not sufficient.

```bash
hostname UbuntuBigDataNode1
echo "UbuntuBigDataNode1" >/etc/hostname
```

On NameNode and DataNode:

```bash
sudo -s
cat >>/etc/hosts <<!
10.0.3.15 master namenode UbuntuBigData
10.0.3.16 UbuntuBigDataNode1 datanode1
!
```

On DataNode: normally the SSH keys should exist because the machines were cloned;
otherwise exchange them manually.

```bash
ssh-keygen -t rsa -P ""
ssh-copy-id -i ~/.ssh/id_rsa.pub hduser@namenode
```

Log in once to get rid of the prompt:

```bash
ssh hduser@namenode
```

On all nodes:

For the cluster add the following configuration to `yarn-site.xml` (replace `UbuntuBigData` with the ResourceManager host):

```vim
 <property>
  <name>yarn.resourcemanager.resource-tracker.address</name>
  <value>UbuntuBigData:8031</value>
 </property>
 <property>
  <name>yarn.resourcemanager.scheduler.address</name>
  <value>UbuntuBigData:8030</value>
 </property>
 <property>
  <name>yarn.resourcemanager.address</name>
  <value>UbuntuBigData:8032</value>
 </property>
```

In `hdfs-site.xml` set the value for `dfs.replication` to 2

On NameNode: make the master aware of all workers

```bash
cat >`$HADOOP_HOME`/etc/hadoop/workers <<!
namenode
datanode1
!
echo "namenode" >`$HADOOP_HOME`/etc/hadoop/masters
```

On all nodes: to ensure files are stored twice, set `dfs.replication` to `2` in `hdfs-site.xml`:

```vim
<configuration>
        <property>
                <name>dfs.replication</name>
                <value>2</value>
        </property>
        <property>
                <name>dfs.permissions</name>
                <value>false</value>
        </property>
        <property>
                <name>dfs.namenode.name.dir</name>
                <value>file:/usr/local/hadoop/hadoopdata/hdfs/namenode</value>
        </property>
        <property>
                <name>dfs.datanode.data.dir</name>
                <value>file:/usr/local/hadoop/hadoopdata/hdfs/datanode</value>
        </property>
</configuration>
```

On NameNode: test call

ONLY on NameNode: start Hadoop (as `hduser`) — on the other nodes it should be started automatically via `pdsh`.

```bash
start-dfs.sh
start-yarn.sh
```

Expected output of the `jps` command on the datanodes:

```bash
jps
```

>13076 DataNode # started on other nodes via `start-dfs.sh`  
>13401 Jps  
>13293 NodeManager # started on other nodes via `start-yarn.sh`

The following creates an HDFS directory and uploads a file:

```bash
hdfs dfs -mkdir -p /user/hduser/data
hdfs dfs -put <myTestfile> /user/hduser/data
```

In the browser open the following path — please verify that the `Replication` value equals `2`:
[](http://localhost:9870/explorer.html#/user/hduser/data)

If the browser shows only one active DataNode, check $HADOOP_HOME/logs for error messages. Common causes:

- SSH key was not exchanged — test SSH from `namenode` to `datanode` and vice versa; both should work without a password.
- Name resolution is incorrect — `namenode` is not configured.
- NameNode is listening only on `localhost:9000` — `telnet namenode 9000` works locally but not from the DataNode. The alias `namenode` must NOT point to `127.0.0.1`.
- UID mismatch: remove data on NameNode: `rm -R /usr/local/hadoop/hadoopdata/*`