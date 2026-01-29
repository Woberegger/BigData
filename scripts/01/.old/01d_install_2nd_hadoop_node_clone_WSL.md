# BigData01 - set up 2nd Hadoop node in WSL

## Guide to set up a 2nd or 3rd node to serve as pure DataNodes (i.e. worker nodes)

On WSL you can do the following:

```PowerShell
cd %USERPROFILE%\Downloads
wsl.exe --shutdown Ubuntu-23.10
wsl.exe --export Ubuntu-23.10 Ubuntu-23.10.backup.tar.gz
wsl.exe --import Ubuntu-23.10-node2 `\%USERPROFILE%\AppData\Local\Packages\Ubuntu-23.10-node2` Ubuntu-23.10.backup.tar.gz
wsl.exe --import Ubuntu-23.10-node2 `\%USERPROFILE%\AppData\Local\Packages\Ubuntu-23.10-node2` .\ubuntu-mantic-wsl-amd64-wsl.rootfs.tar.gz
```

**IMPORTANT:** WSL all WSL instances share the same IP, but they can communicate with each other. Use different SSH ports to distinguish them, e.g. `11222` instead of `10222`.

On DataNode: normally the SSH keys should exist because the machines were cloned; otherwise exchange them manually:

```bash
ssh-keygen -t rsa -P ""
ssh-copy-id -i ~/.ssh/id_rsa.pub -p 11222 hduser@localhost
```

Log in once to remove the prompt:

a) From base node to clone  
b) From clone to base node

```bash
ssh -p 11222 hduser@namenode
ssh -p 10222 hduser@namenode
```

On all nodes: in `yarn-site.xml` add the following (replace `localhost` with the ResourceManager host if needed):

```vim
 <property>
  <name>yarn.resourcemanager.resource-tracker.address</name>
  <value>localhost:8031</value>
 </property>
 <property>
  <name>yarn.resourcemanager.scheduler.address</name>
  <value>localhost:8030</value>
 </property>
 <property>
  <name>yarn.resourcemanager.address</name>
  <value>localhost:8032</value>
 </property>
```

In `hdfs-site.xml` set `dfs.replication` to `2`.

Also define different ports in `hdfs-site.xml` using variables `dfs.datanode.address`, `dfs.datanode.http.address`, `dfs.datanode.ipc.address` and set a separate directory per DataNode in `dfs.datanode.data.dir`. See [](https://stackoverflow.com/questions/25401159/hadoop-multiple-datanodes-on-single-machine) for reference.

See generated file `hdfs-site(for_multiple_datanodes_on_1_server).xml` — note: file not tested; verify contents.

On NameNode: make the master aware of all workers (with WSL there is only one IP, adjust accordingly):

```bash
echo "localhost" >`$HADOOP_HOME`/etc/hadoop/workers
echo "localhost" >`$HADOOP_HOME`/etc/hadoop/masters
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

ONLY on NameNode: start Hadoop (as `hduser`) — on the other nodes it should be started automatically via `pdsh`.

```bash
start-dfs.sh
start-yarn.sh
```

Expected output of the `jps` command on the datanodes:

```bash
jps
```

>13076 DataNode — started on other nodes via `start-dfs.sh`<br>
>13401 Jps<br>
>13293 NodeManager — started on other nodes via `start-yarn.sh`

The following creates an HDFS directory and uploads a file:

```bash
hdfs dfs -mkdir -p /user/hduser/data
hdfs dfs -put <myTestfile> /user/hduser/data
```

In the browser open the following path (please verify that the `Replication` value equals `2`):
[](http://localhost:9870/explorer.html#/user/hduser/data)
