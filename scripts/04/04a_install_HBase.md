# BigData04 - installation of HBase

## Installation of HBase, based on previous installation of Hadoop

we install it to the same directory as our other Hadoop components
```bash
sudo -s
cd /usr/local
```

**Caution:** if the latest version changes, it is possible that the older versions are no longer downloadable from this link.<br>
Use a download link in the archive instead.

```bash
export HBASE_VERSION=2.5.13
wget https://dlcdn.apache.org/hbase/${HBASE_VERSION}/hbase-${HBASE_VERSION}-bin.tar.gz
wget https://dlcdn.apache.org/hbase/${HBASE_VERSION}/hbase-${HBASE_VERSION}-bin.tar.gz.sha512
shasum -a 512 hbase-${HBASE_VERSION}-bin.tar.gz; cat hbase-${HBASE_VERSION}-bin.tar.gz.sha512
tar -xzf hbase-${HBASE_VERSION}-bin.tar.gz
chown -R hduser:hadoop /usr/local/hbase-${HBASE_VERSION}
ln -s /usr/local/hbase-${HBASE_VERSION} HBase
```

All further actions shall be done as user `hduser`

first adapt the local environment variables for the user `hduser` (e.g. in `~/.bashrc`)
```bash
su - hduser

cat >>~/.bashrc <<!
export HBASE_HOME=/usr/local/HBase
#export HBASE_MASTER=namenode # only necessary on additional regionservers
export PATH=\$PATH:\$HBASE_HOME/bin
!

source ~/.bashrc
```

Change the files `$HBASE_HOME/conf/hbase-env.sh` and `${HBASE_HOME}/conf/regionservers` (best done via output redirection as follows)

```bash
cd $HBASE_HOME/conf
export SSH_PORT=22
```

Set JAVA_HOME correctly in file `$HBASE_HOME/conf/hbase-env.sh`, e.g.:

```bash
echo "export JAVA_HOME=/usr/lib/jvm/temurin-11-jdk-$(dpkg --print-architecture)" >>${HBASE_HOME}/conf/hbase-env.sh
```

In the same file, also specify the ssh port if it differs from 22:

```bash
echo "export HBASE_SSH_OPTS=\"-p $SSH_PORT -l hduser\"" >>${HBASE_HOME}/conf/hbase-env.sh
```

It is better to also configure the regionserver file in case additional nodes are added later

```bash
echo "export HBASE_REGIONSERVERS=${HBASE_HOME}/conf/regionservers" >>${HBASE_HOME}/conf/hbase-env.sh
```

Enter here what you get as hostname with `hdfs getconf -confKey fs.defaultFS | cut -d':' -f2 | cut -c3-` (should be "namenode")

```bash
echo $(hdfs getconf -confKey fs.defaultFS | cut -d':' -f2 | cut -c3-) >${HBASE_HOME}/conf/regionservers
```

Check the entry in the regionservers file

```bash
cat ${HBASE_HOME}/conf/regionservers
```

Create backup copy of hbase-site.xml and then edit

```bash
cp -p hbase-site.xml hbase-site.xml.orig
```

Possibly check the URL and port of HDFS (for hbase.rootdir property) before specifying in hbase-site.xml:

```bash
hdfs getconf -confKey fs.defaultFS
```

Create directory for zookeeper data and logs (the "hadoop" folder already belongs to hduser anyway)

```bash
mkdir $HADOOP_HOME/zookeeper
```

Change the file `$HBASE_HOME/conf/hbase-site.xml` (existing entries can be deleted)

```bash
cat >$HBASE_HOME/conf/hbase-site.xml <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
   <property>
     <name>hbase.tmp.dir</name>
     <value>./tmp</value>
   </property>
   <property>
     <name>hbase.unsafe.stream.capability.enforce</name>
     <value>false</value>
   </property>
   <property>
      <name>hbase.rootdir</name>
      <value>hdfs://namenode:9000/hbase</value>
   </property>
   <property>
      <name>hbase.zookeeper.property.dataDir</name>
      <value>/usr/local/hadoop/zookeeper</value>
   </property>
   <property>
     <name>hbase.cluster.distributed</name>
     <value>true</value>
   </property>
   <property>
     <name>hbase.wal.provider</name>
     <value>filesystem</value>
   </property>
   <property>
     <name>hbase.zookeeper.quorum</name>
     <value>namenode</value>
   </property>
   <property>
     <name>hbase.master.info.port</name>
     <value>16010</value>
   </property>
</configuration>
EOF
```

## start and low-level test HBase

1) Start Hadoop

```bash
start-dfs.sh
```

Test with jps whether Hadoop started successfully

To avoid the warning "duplicate implementation of log4j":

```bash
mv $HBASE_HOME/lib/client-facing-thirdparty/log4j-slf4j-impl-2.17.2.jar $HBASE_HOME/lib/client-facing-thirdparty/log4j-slf4j-impl-2.17.2.jar.duplicate
```

2) Start HBase

```bash
$HBASE_HOME/bin/start-hbase.sh
```

### troubleshooting hbase errors

There may be errors when starting up as follows:

a) `/usr/local/hadoop/libexec/hadoop-functions.sh: line 2369: HADOOP_ORG.APACHE.HADOOP.HBASE.UTIL.GETJAVAPROPERTY_USER: invalid variable name`

Solution: Set the following in hbase-env.sh: `export HBASE_DISABLE_HADOOP_CLASSPATH_LOOKUP="true"`

b) Error with ssh:

Solution in hbase-env.sh: `export HBASE_SSH_OPTS="-p 22 -l hduser"`

c) Error as follows: `HADOOP_ORG.APACHE.HADOOP.HBASE.UTIL.GETJAVAPROPERTY_USER: invalid variable name`

Solution: Replace file `$HADOOP_HOME/libexec/hadoop-functions.sh` with the following version [hadoop-functions.sh](https://github.com/Woberegger/BigData/blob/main/scripts/04/hadoop-functions.sh)

d) Error when starting or with command `hbase classpath`

Error: Could not find or load main class org.apache.hadoop.hbase.util.GetJavaProperty

Solution:

```bash
ln -s $HBASE_HOME/lib/hbase-server-2.5.6.jar $HADOOP_HOME/share/hadoop/common/
```

e) If, for example, processes always write that they cannot find jars, try starting the respective daemon in the corresponding order according to start-hbase.sh individually, starting with zookeeper:

```bash
hbase-daemons.sh --config $HBASE_HOME/conf start zookeeper
```

Then check the output in `$HBASE_HOME/logs` to see if there are any errors

```bash
jps | sort -k2
```

## verify correct hbase startup

Should find the following additional processes (of course, the process IDs will differ):
> 6511 HMaster<br>
> 6413 HQuorumPeer<br>
> 6623 HRegionServer<br>

3) Check whether HBase folder was created in HDFS

```bash
hdfs dfs -ls /hbase
```

Otherwise create manually via

```bash
hdfs dfs -mkdir /hbase
```

If you later want to start the exercise from the beginning, it is sufficient to execute the following:

```bash
stop-hbase.sh; hdfs dfs -rm -R /hbase; rm -Rf $HADOOP_HOME/zookeeper/*
```

If there is a message that `namenode is in save mode`, then exit save mode as described below:

```bash
hdfs dfsadmin -safemode leave
```

4) Check status in web browser [](http://<namenodeIP>:16010/master-status)

5) Open HBase Shell and create simple tables with data

```bash
hbase shell
```

The `status` command in hbase shell should provide output like the following:
> 1 active master, 0 backup masters, 1 servers, 0 dead, 3.0000 average load

## Hbase table creation, selection etc.

Execute contents of 04b_HBase_Shell_commands.md and 04c_HBase_Shell_split_table.md

Cheat sheet for HBase shell commands e.g. at [HBase Shell Commands Cheat Sheet](https://sparkbyexamples.com/hbase/hbase-shell-commands-cheat-sheet/)

6) After creating the tables, they should also be visible in the following web GUI [](http://<namenodeIP>:16010/master-status#userTables)

## Additional Options

a) Further examples, e.g., displaying, counting or trying to load data: See book pages 202-203, 207-209

(Note: The numbering in the pdf is 14 higher than the page count in the book, so go to page 216 to view page 202)

> Big Data in der Praxis mit Hadoop" BigDataInderPraxis_Auflage1.pdf

To batch-load into the "peoples" table, please use the file `~/BigData/data/people.csv` and script 04d_HBase_import.md

If you get an error while loading data like the following, please check with `netstat -an | grep 16020` whether the regionserver is not just listening on localhost

Check entries in `/etc/hosts` and in file "regionservers" if you see an error like the following:

> Connection refused: \<hostname\>:16020

b) If you want to try multiple regionservers, you must install hbase on all and expand the following file with the other servers (and restart hbase services)

```bash
$HBASE_HOME/conf/regionservers
```

And on the respective nodes then execute the following

```bash
$HBASE_HOME/bin/hbase-daemon.sh --config $HBASE_HOME/conf start regionserver
```

c) Activate Hbase autostart in analogy to HDFS autostart - and stop it, when the VM shuts down (create systemctl script under `/etc/systemd/system`)

See e.g. instructions at [Ubuntu Server Autostart](https://blog.hartinger.net/ubuntu-server-autostart-eines-commands-einrichten/)