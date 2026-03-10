# BigDataGrp02 - activate rsyslogd

This howto shows, how to activate the `rsyslogd` for remote syslogging, allowing to collect the data with e.g. Flume
Howto was adapted from [](https://betterstack.com/community/guides/logging/how-to-configure-centralised-rsyslog-server/),
which describes the use of a central server - we however want to use Flume instead

check current settings and whether `rsyslogd` is already installed
The location of the configuration file is expected to be `/etc/rsyslog.conf`
```bash
sudo -s
rsyslogd -v
```

check, if service runs, otherwise enable it by calling `enable` and `start`
```bash
systemctl status rsyslog
```

activate follwing lines in `/etc/rsyslog.conf`, which does UDP logging to a higher port (instead of standard port 514)
```vim
# log to different port than usual 514 to be able to use non-privileged user to read from it
*.* @127.0.0.1:47111
```

check, that following line in file `/etc/rsyslog.d/50-default.conf` is activated, which tracks login trials<br>
If you should ant to track something else (e.g. other occurances in /var/log/messages), then additionally activate the other lines with the proper filter
```vim
auth,authpriv.*                 /var/log/auth.log
```

and then restart `syslogd`
```bash
systemctl restart rsyslog
```

log into new shall as user `hduser` for doing Flume configuration
```bash
su - hduser
cd /usr/local/flume
```

generate a flume configuration file, in a first trial to simply log in foreground
```bash
cat >/usr/local/flume/conf/syslogudp.conf.logger_sink <<!
# Name the components on this agent "sysl"
sysl.sources = syslog
sysl.sinks = logger
sysl.channels = memory

sysl.sources.syslog.type = syslogudp
# da wir als "hduser" starten, müssen wir einen Port > 1024 verwenden
sysl.sources.syslog.port = 47111
sysl.sources.syslog.host = localhost
sysl.sources.syslog.channels = memory

# Describe the sink
sysl.sinks.logger.type = logger


# Use a channel which buffers events in memory
sysl.channels.memory.type = memory
sysl.channels.memory.capacity = 1000
sysl.channels.memory.transactionCapacity = 100

# Bind the source and sink to the channel
sysl.sources.syslog.channels = memory
sysl.sinks.logger.channel = memory
!
```
then start the flume agent with the newly generated configuration file
```bash
./bin/flume-ng agent --conf conf/ -f conf/syslogudp.conf.logger_sink -n sysl -Dflume.root.logger=INFO,console
```

test, if the following call appears in `/var/log/syslog` and also in Flume
```bash
logger 'testcall from client' && sleep 1 && tail -n1 /var/log/syslog
```

expected output in Flume is something similar to:
> "INFO  [SinkRunner-PollingRunner-DefaultSinkProcessor] sink.LoggerSink: Event: { ... body: 72 6F 6F 74 3A 20 74 65 73 74 63 61 6C 6C 20 66 root: testcall f }"

then finally change the Flume configuration instead of simple logging to write into Hive or HDFS:<br>
For Hive parameters see example link [](https://community.cloudera.com/t5/Community-Articles/HiveSink-for-Flume/ta-p/245584)
A more simple approach would be to simply direct the Flume sink into HDFS, and then load the generated file into Hive,<br>
as we have shown in lecture 4 with external tables.

The following example writes data into HDFS:
```bash
hdfs dfs -mkdir -p hdfs://namenode:9000/user/hduser/syslog/

cat >/usr/local/flume/conf/syslogudp.conf.hdfs_sink <<!
# Name the components on this agent
sysl.sources = syslog
sysl.sinks = HDFS
sysl.channels = memory

#
sysl.sources.syslog.type = syslogudp
sysl.sources.syslog.port = 47111
sysl.sources.syslog.host = localhost
sysl.sources.syslog.channels = memory

# Describe the sink
sysl.sinks.HDFS.type = hdfs
# use prefix as output from command: hdfs dfs getconf -confKey fs.defaultFS
sysl.sinks.HDFS.hdfs.path = hdfs://namenode:9000/user/hduser/syslog/
# could also use time stamps in path names as in example below
#sysl.sinks.HDFS.hdfs.path = hdfs://namenode:9000/user/hduser/syslog/%y-%m-%d/%H
sysl.sinks.HDFS.hdfs.filePrefix = syslog
sysl.sinks.HDFS.hdfs.fileSuffix = .log
sysl.sinks.HDFS.hdfs.rollInterval = 0
sysl.sinks.HDFS.hdfs.rollCount = 10000
sysl.sinks.HDFS.hdfs.rollSize = 0
# write 1000 records into 1 file (needs to be <= sysl.channels.memory.transactionCapacity)
sysl.sinks.HDFS.hdfs.batchSize = 1000
sysl.sinks.HDFS.hdfs.fileType = DataStream

# Use a channel which buffers events in memory
sysl.channels.memory.type = memory
sysl.channels.memory.capacity = 10000
sysl.channels.memory.transactionCapacity = 1000

# Bind the source and sink to the channel
sysl.sources.syslog.channels = memory
sysl.sinks.HDFS.channel = memory
!
```

start the agent to use the different config file for HDFS sink
```bash
./bin/flume-ng agent --conf conf/ -f conf/syslogudp.conf.hdfs_sink -n sysl
```

In order to generate a few more data to see, if HDFS file was generated:
```bash
for ((i=0;i<=200;i++)); do logger "log msg nr $i"; done
```

Show the generated HDFS data using GUI under [](http://<namenodeIP>:9870/explorer.html#/user/hduser/syslog)
(the most recently generated file gets extension `.tmp` and will only be renamed, once the flume-ng commando was stopped)

When working with HDFS and loading data with Hive from file, you can interactively load the data into Hive
(writing data directly to Hive has the advantage, that it permanently adds newly occuring events

do the following only once to connect to beeline, the other blocks are the HiveQL commands:
```bash
export HIVE_CONNECT_STRING=localhost:10000
beeline --verbose -u jdbc:hive2://$HIVE_CONNECT_STRING scott tiger
   set hive.execution.engine=mr;
   set hive.metastore.warehouse.dir;
   use default;
```

You can provide the path `/user/hduser/syslog/` without a particular file name, then more data files can be loaded at once
```sql
CREATE TABLE logevents (logline STRING);
LOAD DATA INPATH '/user/hduser/syslog/' OVERWRITE INTO TABLE logevents;
```

additional task: if the above works, you can change the Flume configuration file to directly write into Hive.<br>
In that case the Hive table has to be created with following syntax:<br>
(for simplicity we load all records into the table and do join with string operations)

```sql
   DROP TABLE logevents;
   CREATE TABLE IF NOT EXISTS logevents (logline STRING)
    COMMENT 'Syslog events as complete line'
    STORED AS ORC
    LOCATION '/user/hduser/hive_external/logevents';
```