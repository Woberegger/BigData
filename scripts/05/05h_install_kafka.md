# siehe Tutorial https://kafka.apache.org/quickstart
sudo -s
cd /usr/local
export KAFKA_VERSION=3.9.1
wget https://dlcdn.apache.org/kafka/${KAFKA_VERSION}/kafka_2.13-${KAFKA_VERSION}.tgz
tar -xzf kafka_2.13-${KAFKA_VERSION}.tgz
ln -s kafka_2.13-${KAFKA_VERSION} kafka
chown -R hduser:hadoop kafka*

su - hduser
cat >> ~/.bashrc <<!
export KAFKA_HOME=/usr/local/kafka
export PATH=\$PATH:\$KAFKA_HOME/bin
!
source ~/.bashrc

# da Kafka den Zookeeper mitbenutzt, den wir ja mit HBase betreiben, müssen wir neben DFS/YARN auch HBase starten
start-hbase.sh
# nach ein paar Sekunden (wenn hochgefahren), sollte man ein Listen auf Port 2181 sehen
netstat -an | grep 2181

# eigenartigerweise funktioniert es nicht, wenn man $KAFKA_HOME/lib dazuhängt, daher besser komplett löschen, dann geht das
# (weil scheinbar sonst Pfade von Flume verwendet werden mit Libraries, die nicht kompatibel sind)
unset CLASSPATH
$KAFKA_HOME/bin/kafka-server-start.sh $KAFKA_HOME/config/server.properties &

jps | grep Kafka # sollte den laufenden Prozess finden

# mögliches Problem: sollte Kafka zuvor irrtümlich als root gestartet worden sein, dann als root user folgende Verzeichnisse löschen:
# rm -Rf /tmp/kafka-logs/ /usr/local/kafka/logs/

# erstelle ein sogenanntes "Topic" - in dem Fall mit Namen "quickstart-events"
$KAFKA_HOME/bin/kafka-topics.sh --create --topic quickstart-events --bootstrap-server localhost:9092

# schreibe Events ins Topic
echo -e "this is my first topic\nthis is my second one" | $KAFKA_HOME/bin/kafka-console-producer.sh --topic quickstart-events --bootstrap-server localhost:9092

# und dann "konsumiere" die zuvor geschriebenen Events
$KAFKA_HOME/bin/kafka-console-consumer.sh --topic quickstart-events --from-beginning --bootstrap-server localhost:9092
# beende consumer mit <Ctrl>c

# danach erstellen wir einen Wordcount task - dafür brauchen wir Plaintext-Input und Wordcount Topic
# ACHTUNG: bitte Zeile für Zeile eingeben, da man manchmal mit <Ctrl>c abbrechen muss, bevor man das nächste Kommando eingibt
$KAFKA_HOME/bin/kafka-topics.sh --create --topic streams-plaintext-input --bootstrap-server localhost:9092 --replication-factor 1 --partitions 1
$KAFKA_HOME/bin/kafka-topics.sh --create --topic streams-wordcount-output --bootstrap-server localhost:9092 --replication-factor 1 --partitions 1 --config cleanup.policy=compact
$KAFKA_HOME/bin/kafka-run-class.sh org.apache.kafka.streams.examples.wordcount.WordCountDemo
# und dann produzieren wir einfach einen Input für das Wordcount
echo -e "Das Wort Das kommt doppelt vor im Text" | $KAFKA_HOME/bin/kafka-console-producer.sh --bootstrap-server localhost:9092 --topic streams-plaintext-input
# und der Consumer sollte das dann empfangen haben
$KAFKA_HOME/bin/kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic streams-wordcount-output --from-beginning --property print.key=true --property print.value=true --property key.deserializer=org.apache.kafka.common.serialization.StringDeserializer --property value.deserializer=org.apache.kafka.common.serialization.LongDeserializer

# Erwartete Ausgabe:
#das     1
#wort    1
#das     2
#kommt   1
#doppelt 1
#vor     1
#im      1
#text    1

# liste alle generierten topics
$KAFKA_HOME/bin/kafka-topics.sh --bootstrap-server localhost:9092 --describe
