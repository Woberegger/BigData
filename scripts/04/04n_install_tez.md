# BigData04 - install Tez

as we have heard in the lecture, Tez is a more efficient execution engine than MapReduce,
which can be used as an alternative to MapReduce for Hive. It is based on a directed acyclic graph (DAG) of tasks,
which allows for more flexible and efficient execution of queries.
In this part, we will install Tez and configure Hive to use it as the execution engine.

download and install Tez
```bash
sudo -s
cd /usr/local
export TEZ_VERSION=0.10.4
wget https://dlcdn.apache.org/tez/${TEZ_VERSION}/apache-tez-${TEZ_VERSION}-bin.tar.gz
tar -xzf apache-tez-${TEZ_VERSION}-bin.tar.gz
ln -s apache-tez-${TEZ_VERSION}-bin tez
chown -R hduser:hadoop apache-tez-${TEZ_VERSION}-bin
```

following actions done as user `hduser` (and not as root)
```bash
su - hduser
export TEZ_VERSION=0.10.4
export TEZ_HOME=/usr/local/tez
cd $TEZ_HOME
```

in order to use `Tez` as execution engine for Hive, we need to make it available in the classpath of Hive and also in HDFS.
```bash
hdfs dfs -mkdir -p /apps/tez-${TEZ_VERSION}
hdfs dfs -put share/tez.tar.gz /apps/tez-${TEZ_VERSION}/
```

adapt file $HADOOP_HOME/etc/hadoop/hdfs-site.xml manually:
```xml
    <property>
      <name>dfs.namenode.decommission.interval</name>
      <value>30</value>
    </property>
    <property>
      <name>dfs.client.datanode-restart.timeout</name>
      <value>30</value>
    </property>
```

similarly adapt file $HADOOP_HOME/etc/hadoop/yarn-site-xml (because of Tez-UI)
```xml
    <property>
      <description>Indicate to clients whether Timeline service is enabled or not.
      If enabled, the TimelineClient library used by end-users will post entities
      and events to the Timeline server.</description>
      <name>yarn.timeline-service.enabled</name>
      <value>true</value>
    </property>
    <property>
      <description>The hostname of the Timeline service web application.</description>
      <name>yarn.timeline-service.hostname</name>
      <value>localhost</value>
    </property>
    <property>
      <description>Enables cross-origin support (CORS) for web services where
      cross-origin web response headers are needed. For example, javascript making
      a web services request to the timeline server.</description>
      <name>yarn.timeline-service.http-cross-origin.enabled</name>
      <value>true</value>
    </property>
    <property>
      <description>Publish YARN information to Timeline Server</description>
      <name> yarn.resourcemanager.system-metrics-publisher.enabled</name>
      <value>true</value>
    </property>
```

and following properties are required in hive-site.xml:
```xml
  <property>
    <name>tez.lib.uris</name>
    <value>hdfs:///apps/tez-0.10.4</value>
  </property>
  <property>
    <name>hive.tez.container.size</name>
    <value>2048</value>
  </property>
  <property>
    <name>hive.tez.java.opts</name>
    <value>-Xmx2048m</value>
  </property>
  <!--settings for Tez local mode -->
  <property>
    <name>tez.local.mode</name>
    <value>true</value>
  </property>
  <property>
    <name>tez.runtime.optimize.local.fetch</name>
    <value>true</value>
  </property>
  <property>
    <name>hive.jar.directory</name>
    <value>/tmp/hive-jars</value>
    <description>directory, where Hive can place automatically created Jar files</description>
  </property>
  <property>
    <name>hive.user.install.directory</name>
    <value>/tmp/hive-user</value>
    <description>User-specific directory foir installing Hive resources</description>
  </property>
```

furthermore set property for hive execution engine to tez, either in hive-site.xml or in beeline after connecting to the server, but before executing any queries:
```xml
  <property>
    <name>hive.execution.engine</name>
    <value>tez</value>
  </property>
```

adapt the TEZ configuration file itself - use the template file as basis
```bash
cd ${TEZ_HOME}/conf
cp tez-default-template.xml tez-site.xml
```

set the following in tez-site.xml (with correct TEZ-Version), which was loaded before into HDFS
```xml
  <property>
     <name>tez.lib.uris</name>
     <value>/apps/tez-0.10.4/tez.tar.gz</value>
     <type>string</type>
  </property>
  <property>
     <name>tez.runtime.convert.user-payload.to.history-text</name>
     <value>true</value>
  </property> 
```

and set the value for the already existing property tez.tez-ui.history-url.base as shown below:
```xml
  <property>
     <description>URL for where the Tez UI is hosted</description>
     <name>tez.tez-ui.history-url.base</name>
     <value>http://namenode:9001</value>
  </property>
```

create directories, which are needed for temporary files
```bash
mkdir /tmp/hive-jars /tmp/hive-user
```

after that restart HDFS and YARN (when operating HDFS in local mode, only DFS is necessary to run)
```bash
stop-dfs.sh; start-dfs.sh
#stop-yarn.sh; start-yarn.sh
```

check, if the following is correct or if other Hadoop paths like \$HADOOP_HOME/share/hadoop/common/lib or \$HBASE_HOME/lib should be added as well...
```bash
#cat >> ${HIVE_HOME}/conf/hive-env.sh <<!
#export HADOOP_CLASSPATH=${TEZ_HOME}/conf:${TEZ_HOME}/*:${TEZ_HOME}/lib/*
#!
```

in order to not have problems with multiple versions of slf4j, which is a logging framework, we need to make sure that only one version is available in the classpath.
Tez uses slf4j-reload4j, which is not compatible with the version used by Hive. Therefore, we need to remove the slf4j-reload4j jar from the Tez lib directory and place it somewhere else, so that it is not picked up by Hive.
```bash
mv $TEZ_HOME/lib/slf4j-reload4j-*.jar /tmp/
```

adapt user environment of `hduser`
```bash
cat >> ~/.bashrc <<!
export TEZ_VERSION=0.10.4
export TEZ_HOME=/usr/local/tez
export TEZ_CONF_DIR=\$TEZ_HOME/conf
export TEZ_JARS=\$TEZ_HOME

# For enabling hive to use the Tez engine
if [ -z "\$HIVE_AUX_JARS_PATH" ]; then
   export HIVE_AUX_JARS_PATH="\$TEZ_JARS"
else
   export HIVE_AUX_JARS_PATH="\$HIVE_AUX_JARS_PATH:\$TEZ_JARS"
fi
!

source ~/.bashrc
```

## Jetty GUI runner for TEZ GU
(Jetty is an own small webserver) - *I'm not sure, if we need it of can skip this step completely!*
```bash
cd $TEZ_HOME
wget https://repository.apache.org/content/repositories/releases/org/apache/tez/tez-ui/${TEZ_VERSION}/tez-ui-${TEZ_VERSION}.war
export JETTY_VERSION=11.0.18
wget https://repo1.maven.org/maven2/org/eclipse/jetty/jetty-runner/${JETTY_VERSION}/jetty-runner-${JETTY_VERSION}.jar
# start webserver in background - you can choose any not-used port, which is enabled on the firewall
java -jar $(ls jetty-runner*.jar) --port 8089 tez-ui-${TEZ_VERSION}.war &
```

## test Tez with Hive
restart hiveserver to pick up all changes
```bash
pkill -f HiveServer2
hive --service hiveserver2 --hiveconf hive.server2.thrift.port=10000 &
```

```bash
hadoop jar Hadoopwordcount.jar /input/Bibel.txt /output/Bibel.tez/
```

if that works, then do similar calls as in 04l_hive_commands_part2.md, but with Tez as execution engine:

```bash
beeline --verbose -u jdbc:hive2://localhost:10000 scott tiger
   -- important: use tez as execution engine for complex queries (when already set in hive-site.xml, this is not necessary)
   set hive.execution.engine=tez;
   set hive.metastore.warehouse.dir;
   show databases;
   show tables;
   use default;
   -- the following seems to work, as no mr/tez is involved
   select * from sales limit 20;
   -- but the following 2 fail, when tez is not correctly configured
   -- although heapsize was set in hive-site.xml I get error "java.lang.OutOfMemoryError: Java heap space"
   CREATE TABLE IF NOT EXISTS word_counts_tez AS
   SELECT word, count(1) AS count FROM
    (SELECT explode(split(line, ' ')) AS word FROM docs) temp
   GROUP BY temp.word
   ORDER BY temp.word;
   -- this however works, it does not need so much memory
   select s.cust_id, sum(s.sales) as summe from sales s group by cust_id limit 20;
```