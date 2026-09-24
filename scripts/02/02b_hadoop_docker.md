# BigData02 - Hadoop in Docker Containers

Download sources from the GitHub repo if not already done.

Container images are pulled from [https://hub.docker.com/r/bde2020/hadoop-base](https://hub.docker.com/r/bde2020/hadoop-base]).
The configuration from [https://github.com/big-data-europe/docker-hadoop/tree/master](https://github.com/big-data-europe/docker-hadoop/tree/master) has been adapted for a total of 3 (instead of 2) DataNodes.

clone git repo, if not yet done so in previous lecture...
```bash
su - hduser
cd ~
git clone https://github.com/Woberegger/BigData/
```

 stop locally installed DFS, when using the docker version, as some ports might be shared
```bash
stop-dfs.sh
```

Build Docker containers after downloading the sources (check the path and adjust if necessary).

```bash
sudo -s
export HADOOPDOCKERDIR=~hduser/BigData/src/docker-hadoop/
cd $HADOOPDOCKERDIR
apt install docker-compose # if not yet installed
docker-compose up -d
```

The output of `docker ps | cut -d' ' -f4 | sort` should look like this (3 DataNodes and 1 NameNode, NodeManager, ResourceManager and HistoryServer):

```bash
docker ps | cut -d' ' -f4 | sort
```
> bde2020/hadoop-datanode:latest<br>
> bde2020/hadoop-datanode:latest<br>
> bde2020/hadoop-datanode:latest<br>
> bde2020/hadoop-historyserver:2.0.0-hadoop3.2.1-java8<br>
> bde2020/hadoop-namenode:2.0.0-hadoop3.2.1-java8<br>
> bde2020/hadoop-nodemanager:2.0.0-hadoop3.2.1-java8<br>
> bde2020/hadoop-resourcemanager:2.0.0-hadoop3.2.1-java8<br>

Also check which IPs the containers received.

```bash
docker network inspect docker-hadoop_default
```

It may be necessary to open the ports via `iptables` if they are not automatically exposed by the port mapping.

```bash
iptables -I INPUT 1 -p tcp --dport 8088 -j ACCEPT
iptables -I INPUT 1 -p tcp --dport 9870 -j ACCEPT
```

## test word-count program

Copy the word-count program into the container (better: the one we build in lecture 3).

```bash
export HADOOPDOCKERDIR=~hduser/BigData/src/docker-hadoop/
docker cp $HADOOPDOCKERDIR/../wordcount/Hadoopwordcount.jar namenode:/tmp/Hadoopwordcount.jar
```

Connect to the `namenode` container.

```bash
docker exec -it namenode bash
```

Execute the following commands inside the container to download and run test data.

```bash
cd /tmp
curl -o el_quijote.txt https://gist.github.com/jsdario/6d6c69398cb0c73111e49f1218960f79#file-el_quijote-txt
curl -o mapreduce.jar https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-mapreduce-examples/2.7.1/hadoop-mapreduce-examples-2.7.1-sources.jar
```

Create directories in HDFS.

```bash
hdfs dfs -mkdir -p /input
hdfs dfs -mkdir -p /output
hdfs dfs -put ./el_quijote.txt /input/
```

If the directory exists from previous tests, delete it.

```bash
hdfs dfs -rm -R /output/elquijote
hadoop jar Hadoopwordcount.jar /input/el_quijote.txt /output/elquijote
```

```bash
docker exec -i --tty=false resourcemanager bash <<!
   \$HADOOP_HOME/bin/yarn --config \$HADOOP_CONF_DIR resourcemanager &
!
```

If the last line prints 'Job was successful', then everything likely worked.

You can view the file content via [](http://localhost:<VM-IP>/explorer.html#/output/elquijote) or faster:

```bash
hdfs dfs -get /output/elquijote/part-r-00000 /tmp/wordcountresult.txt
tail -n 50 /tmp/wordcountresult.txt
```

exit from the Docker container.

```bash
exit
```

To stop the containers you can also use the "hard" way ...

```bash
for i in $(docker container list | tail +2 | cut -d' ' -f1); do docker container stop $i; done
```

... or better:

```bash
docker-compose down
```

If you want to start over (and try again from scratch), run the following (examples):

```bash
docker container rm namenode
docker container rm datanode
docker container rm datanode2
docker container rm nodemanager
docker container rm resourcemanager
docker container rm historyserver
```

## Troubleshooting

If the following exception occurs, the `HadoopWordCount.jar` was compiled with a newer Java version; the container has Java 8 installed:

> Exception in thread "main" java.lang.UnsupportedClassVersionError: at/fhj/WordCount has been compiled by a more recent version<br>
> of the Java Runtime (class file version 55.0), this version of the Java Runtime only recognizes class file versions up to 52.0


If the following error occurs, connect in a second session to the ResourceManager and start it there.

> INFO ipc.Client: Retrying connect to server: resourcemanager/172.19.0.3:8032. Already tried 9 time(s);<br>
> retry policy is RetryUpToMaximumCountWithFixedSleep(maxRetries=10, sleepTime=1000 MILLISECONDS)

