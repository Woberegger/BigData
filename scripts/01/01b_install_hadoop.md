# BigData01 - install hadoop

## Download and install Hadoop
download it in suitable version (best take the one listed here, which was tested)
```bash
sudo -s
```

```bash
cd /usr/local
export HADOOP_VERSION=3.5.0
wget https://dlcdn.apache.org/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz --no-check-certificate
wget https://downloads.apache.org/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz.sha512 --no-check-certificate
```

it is good practice to verify, that a download is not corrupt or was manipulated
(the ShaSum File references a different file name, therefore it has to be corrected with "sed")
optional call "shasum -a 512 hadoop-${HADOOP_VERSION}.tar.gz" and manually cross-check the output against *.sha512 file
```bash
sed -i 's/-RC1//' hadoop-${HADOOP_VERSION}.tar.gz.sha512
shasum -a 512 hadoop-${HADOOP_VERSION}.tar.gz -c hadoop-${HADOOP_VERSION}.tar.gz.sha512
```

unpack the archive and generate a link, so that after a later version update only the link needs to be changed
```bash
tar -xzf hadoop-${HADOOP_VERSION}.tar.gz
# or in 2 steps: gzip -d hadoop-${HADOOP_VERSION}.tar.gz && tar -xf hadoop-${HADOOP_VERSION}.tar
ln -sf hadoop-${HADOOP_VERSION} hadoop
# remove the installation file to gain space
rm hadoop-${HADOOP_VERSION}.tar.gz
```

the user "hduser" will be the "master" of that directory
```bash
chown -R hduser:hadoop hadoop*
```

## configure hadoop

set environment variables in .bashrc of user "hduser"

```bash
su - hduser
export JAVA_FLAVOR=temurin-11-jdk
```

fill environment file .bashrc with system variables
>Question: What are the Backslash-Quotes used for?

```bash
cat >>~/.bashrc <<EOF
# Java (a copy of what is already in /etc/profile.d/java.sh)
export JAVA_HOME=/usr/lib/jvm/${JAVA_FLAVOR}-$(dpkg --print-architecture)

export HADOOP_INSTALL=/usr/local/hadoop
export HADOOP_HOME=\$HADOOP_INSTALL
export HADOOP_MAPRED_HOME=\$HADOOP_INSTALL
export HADOOP_COMMON_HOME=\$HADOOP_INSTALL
export HADOOP_HDFS_HOME=\$HADOOP_INSTALL
export HADOOP_YARN_HOME=\$HADOOP_INSTALL
export HADOOP_COMMON_LIB_NATIVE_DIR=\$HADOOP_INSTALL/lib/native
export HADOOP_OPTS="-Djava.library.path=\$HADOOP_INSTALL/lib/native"
export YARN_HOME=\$HADOOP_HOME

export PATH=\$PATH:\$JAVA_HOME/bin:\$HADOOP_INSTALL/bin:\$HADOOP_INSTALL/sbin

export PDSH_RCMD_TYPE=ssh
EOF
```

as the content, which was now appended to .bashrc, will only be interpreted upon new login,
we have to either re-login or read it with "source" command.
>Question: What is the source command for? Why do we not simply call .bashrc? Does .bashrc have executable rights?

```bash
source ~/.bashrc
```

### adapt Hadoop configuration files (as user "hduser")

unfortunately this is also needed here (and not sufficient in .bashrc)
```bash
echo "export JAVA_HOME=/usr/lib/jvm/${JAVA_FLAVOR}-$(dpkg --print-architecture)" >>${HADOOP_HOME}/etc/hadoop/hadoop-env.sh
```

here we better take common configuration files, so that all have the same settings initially:

adapt /usr/local/hadoop/etc/hadoop/core-site.xml: Settings for the HDFS distributed file system
```bash
cat >${HADOOP_CONF_DIR}/hdfs-site.xml <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
   <property>
      <name>dfs.replication</name>
      <value>2</value>
   </property>
   <property>
      <name>dfs.namenode.maintenance.replication.min</name>
      <value>1</value>
   </property>
   <property>
      <name>dfs.namenode.hosts.provider.classname</name>
      <value>org.apache.hadoop.hdfs.server.blockmanagement.CombinedHostFileManager</value>
   </property>
   <property>
      <name>dfs.hosts</name>
      <value>/usr/local/hadoop/etc/hadoop/hosts</value>
   </property>
   <property>
      <name>dfs.permissions.enabled</name>
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
   <property>
      <name>dfs.namenode.heartbeat.recheck-interval</name>
      <value>15000</value>
      <description>Determines datanode heartbeat interval in milliseconds</description>
   </property>
   <property>
      <!-- we use the minimum allowed limit, so that we do not consume too much space in our environment -->
      <name>dfs.blocksize</name>
      <value>131072</value>
   </property>
   <property>      
      <name>dfs.namenode.fs-limits.min-block-size</name>
      <value>131072</value>
   </property>   
</configuration>
EOF
```

adapt /usr/local/hadoop/etc/hadoop/core-site.xml: Settings for hadoop in general<br>
*(in order to later have identical configuration files between primary and other nodes, we use logical name "namenode"
instead of "localhost") - this name has to exist in /etc/hosts, e.g. "namenode"*
```bash
cat >${HADOOP_CONF_DIR}/core-site.xml <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
	<property>
		<name>fs.defaultFS</name>
		<value>hdfs://namenode:9000</value>
	</property>
	<property>
		<name>hadoop.tmp.dir</name>
		<value>/usr/local/hadoop/hadoopdata/hdfs/tmp</value>
	</property>
</configuration>
EOF
```

adapt /usr/local/hadoop/etc/hadoop/mapred-site.xml: Settings for Map Reduce jobs
```bash
cat >${HADOOP_CONF_DIR}/mapred-site.xml <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
   <property>
      <name>mapreduce.shuffle.port</name>
      <value>13562</value>
   </property>
   <property>
      <name>mapreduce.job.tracker</name>
      <value>namenode:9001</value>
   </property>
   <property>
      <name>mapreduce.jobhistory.address</name>
      <value>namenode:10020</value>
   </property>
   <property>
      <name>mapreduce.jobhistory.webapp.address</name>
      <value>namenode:19888</value>
   </property>   
   <!-- IMPORTANT: with value "yarn" all NodeManager processes on all datanodes must correctly talk to Namenode (only with "yarn" the jobhistory is on port 8088 is available)
                   therefore better use "local", this should always work -->
   <property>
      <name>mapreduce.framework.name</name>
      <value>local</value>
   </property>
</configuration>
EOF
```

adapt /usr/local/hadoop/etc/hadoop/yarn-site.xml: Settings for yarn Ressource manager
```bash
cat >${HADOOP_CONF_DIR}/yarn-site.xml <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
	<property>
		<name>yarn.nodemanager.aux-services</name>
		<value>mapreduce_shuffle</value>
	</property>
	<property>
		<name>yarn.nodemanager.aux-services.mapreduce.shuffle.class</name>
      <value>org.apache.hadoop.mapred.ShuffleHandler</value>
	</property>
	<property>
		<name>yarn.nodemanager.vmem-pmem-ratio</name>
		<value>3</value>
	</property>
	<property>
		<name>yarn.nodemanager.delete.debug-delay-sec</name>
		<value>600</value>
	</property>
	<property>
		<name>yarn.nodemanager.vmem-check-enabled</name>
		<value>false</value>
	</property>
   <!-- IMPORTANT: set this parameter to use Yarn and not local mode for computation -->
   <property>
      <name>yarn.resourcemanager.hostname</name>
      <value>namenode</value>
   </property>
</configuration>
EOF
```

### create necessary directories in the "normal" file system, which Hadoop uses (as user "hduser")
```bash
mkdir -p /usr/local/hadoop/hadoopdata/hdfs/tmp
mkdir -p /usr/local/hadoop/hadoopdata/hdfs/namenode
mkdir -p /usr/local/hadoop/hadoopdata/hdfs/datanode
mkdir -p /usr/local/hadoop/hadoopdata/hdfs/input
```

continue with script 01c_ssh_keys_for_hadoop.md ...