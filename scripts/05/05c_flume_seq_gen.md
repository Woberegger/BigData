# BigData05 - Flume sequence generator
This example shall simply generate numbers from a sequence generator and write them to HDFS with Flume.

*IMPORTANT:* All commands are executed as user `hduser` - so make sure to switch to this user before executing the commands.

verify again, that Flume works (and take care, that hdfs is running, too)
```bash
su - hduser
start-dfs.sh
flume-ng version
```

create Sequence Generator configuration file:
```bash
cat >$FLUME_HOME/conf/seq_gen.conf <<!
# Naming the components on the current agent
SeqGenAgent.sources = SeqSource   
SeqGenAgent.channels = MemChannel 
SeqGenAgent.sinks = HDFS 
 
# Describing/Configuring the source 
SeqGenAgent.sources.SeqSource.type = seq
  
# Describing/Configuring the sink
SeqGenAgent.sinks.HDFS.type = hdfs
#IMPORTANT: use prefix as output from command: hdfs getconf -confKey fs.defaultFS
SeqGenAgent.sinks.HDFS.hdfs.path = hdfs://namenode:9000/user/hduser/sink
SeqGenAgent.sinks.HDFS.hdfs.filePrefix = log 
SeqGenAgent.sinks.HDFS.hdfs.rollInterval = 0
SeqGenAgent.sinks.HDFS.hdfs.rollCount = 10000
SeqGenAgent.sinks.HDFS.hdfs.fileType = DataStream 
 
# Describing/Configuring the channel 
SeqGenAgent.channels.MemChannel.type = memory 
SeqGenAgent.channels.MemChannel.capacity = 1000 
SeqGenAgent.channels.MemChannel.transactionCapacity = 100 
 
# Binding the source and sink to the channel 
SeqGenAgent.sources.SeqSource.channels = MemChannel
SeqGenAgent.sinks.HDFS.channel = MemChannel
!
```

Test call for flume agent<br>
(the parameters can be given in short or long form, e.g. -c or --conf)

> the flume-ng command would run infinitely, so just wait for a few seconds and then stop it with `<Ctrl>c`
```bash
hdfs dfs -rm /user/hduser/sink/*
cd $FLUME_HOME
./bin/flume-ng agent --conf conf/ -f conf/seq_gen.conf -n SeqGenAgent -Dflume.root.logger=INFO,console
```

show generated files in HDFS:
```bash
hdfs dfs -ls -R /user/hduser/sink
```

show contents of those files (with the generated sequence numbers):
```bash
hdfs dfs -cat /user/hduser/sink/<FileName>
```

if all is working, then you should delete the files again in order to free up space
```bash
hdfs dfs -rm /user/hduser/sink/log*
```
