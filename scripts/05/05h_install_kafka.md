# BigData05 - install kafka (optional)

Kafka is a distributed streaming platform that can be used for building real-time data pipelines and streaming applications.

see tutorial [Kafka-Quickstart](https://kafka.apache.org/quickstart)

```bash
sudo -s
cd /usr/local
export KAFKA_VERSION=3.9.1
wget https://dlcdn.apache.org/kafka/${KAFKA_VERSION}/kafka_2.13-${KAFKA_VERSION}.tgz
tar -xzf kafka_2.13-${KAFKA_VERSION}.tgz
ln -s kafka_2.13-${KAFKA_VERSION} kafka
chown -R hduser:hadoop kafka*
```

set environment for Kafka for `hduser`

```bash
su - hduser
cat >> ~/.bashrc <<!
export KAFKA_HOME=/usr/local/kafka
export PATH=\$PATH:\$KAFKA_HOME/bin
!
source ~/.bashrc
```

as Kafka uses Zookeeper, which we operate with HBase, we must start HBase in addition to DFS
```bash
start-dfs.sh
start-hbase.sh
```

After a few seconds (when started), you should see a listener on port 2181
```bash
sleep 3
netstat -an | grep 2181
```

> Strangely, it doesn't work if you append $KAFKA_HOME/lib, so it's better to completely unset it, then it works<br>
> (because apparently Flume paths are used otherwise with libraries that are not compatible)

```bash
unset CLASSPATH
$KAFKA_HOME/bin/kafka-server-start.sh $KAFKA_HOME/config/server.properties &
```

this should find the running process
```bash
jps | grep Kafka
```

> Possible problem: if Kafka was mistakenly started as root previously, <br>
> then as root user delete the following directories:
```bash
rm -Rf /tmp/kafka-logs/ /usr/local/kafka/logs/
```

## sample topic
Create a so-called "Topic" - in this case named "quickstart-events"
```bash
$KAFKA_HOME/bin/kafka-topics.sh --create --topic quickstart-events --bootstrap-server localhost:9092
```

Write events to the topic by sending it to a producer job
```bash
echo -e "this is my first topic\nthis is my second one" | $KAFKA_HOME/bin/kafka-console-producer.sh --topic quickstart-events --bootstrap-server localhost:9092
```

and then "consume" the previously written events in a Kafka consumer job<br>
(End consumer with `<Ctrl>c`)

```bash
$KAFKA_HOME/bin/kafka-console-consumer.sh --topic quickstart-events --from-beginning --bootstrap-server localhost:9092
```

## wordcount task with Kafka

After that, we create a Wordcount task - for that we need Plaintext input and the Wordcount topic

> *ATTENTION:* please enter line by line, as you sometimes have to abort with `<Ctrl>c` before entering the next command
```bash
$KAFKA_HOME/bin/kafka-topics.sh --create --topic streams-plaintext-input --bootstrap-server localhost:9092 --replication-factor 1 --partitions 1
```
```bash
$KAFKA_HOME/bin/kafka-topics.sh --create --topic streams-wordcount-output --bootstrap-server localhost:9092 --replication-factor 1 --partitions 1 --config cleanup.policy=compact
```
```bash
$KAFKA_HOME/bin/kafka-run-class.sh org.apache.kafka.streams.examples.wordcount.WordCountDemo
```

and then we simply produce input for the wordcount

```bash
echo -e "Das Wort Das kommt doppelt vor im Text" | $KAFKA_HOME/bin/kafka-console-producer.sh --bootstrap-server localhost:9092 --topic streams-plaintext-input
```
and the consumer should then have received it
```bash
$KAFKA_HOME/bin/kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic streams-wordcount-output --from-beginning --property print.key=true --property print.value=true --property key.deserializer=org.apache.kafka.common.serialization.StringDeserializer --property value.deserializer=org.apache.kafka.common.serialization.LongDeserializer
```

Expected output:

> das     1<br>
> wort    1<br>
> das     2<br>
> kommt   1<br>
> doppelt 1<br>
> vor     1<br>
> im      1<br>
> text    1<br>

finally (for verification) list all generated topics
```bash
$KAFKA_HOME/bin/kafka-topics.sh --bootstrap-server localhost:9092 --describe
```
