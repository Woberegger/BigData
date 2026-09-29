# BigData05 - Flume netcat example

we will install a simple Flume configuration to listen to a port and write the received data to the console.

*IMPORTANT:* All commands are executed as user `hduser` - so make sure to switch to this user before executing the commands.

verify again, that Flume works (and take care, that hdfs is running, too)
```bash
su - hduser
start-dfs.sh
flume-ng version
```

create netcat listener configuration:<br>
the tags `a1`, `r1`, `k1` and `c1` are freely defined names without meaning - only the relationship to each other must fit.
(one could probably name this more nicely with AgentName, Source, Sink and Channel)

```bash
cat >$FLUME_HOME/conf/example.conf <<!
# example.conf: A single-node Flume configuration
# Name the components on this agent
a1.sources = r1
a1.sinks = k1
a1.channels = c1

# Describe/configure the source
a1.sources.r1.type = netcat
a1.sources.r1.bind = localhost
a1.sources.r1.port = 44444

# Describe the sink
a1.sinks.k1.type = logger

# Use a channel which buffers events in memory
a1.channels.c1.type = memory
a1.channels.c1.capacity = 1000
a1.channels.c1.transactionCapacity = 100

# Bind the source and sink to the channel
a1.sources.r1.channels = c1
a1.sinks.k1.channel = c1
!
```

## session 1: test call for this agent
```bash
cd $FLUME_HOME
bin/flume-ng agent -n a1 -c conf -f conf/example.conf
```

## session 2: test connection to agent

in 2nd session start `telnet` or better `netcat`/`nc` - there then simply enter various strings and finish with `ENTER` key.

> an "OK" output is visible (session 2)<br>
> and in the agent's window (session 1) the inputs appear as hex and plain text

```bash
netcat localhost 44444
```
