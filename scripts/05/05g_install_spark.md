# BigData05 - install spark (optional)

optionally install spark to see, how processing of streaming data works with Spark Streaming.
Spark is a powerful framework for distributed data processing and can be used for batch and stream processing.

```bash
sudo -s
cd /usr/local
export SPARK_VERSION=3.5.3
wget https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop3.tgz
tar -xzf spark-${SPARK_VERSION}-bin-hadoop3.tgz
ln -s spark-${SPARK_VERSION}-bin-hadoop3 spark
rm spark-${SPARK_VERSION}-bin-hadoop3.tgz # to save space
chown -R hduser:hadoop spark*
```

The easiest way is to create Spark commands in Python, so pipx is installed as the Python package manager
```bash
apt install pipx
```

And then the "pyspark" package (*IMPORTANT:* as user `hduser` and not as root, because pipx installs the binaries and executable scripts to the home directory of the user)
```bash
su - hduser
pipx install pyspark
```

adapt environment for Spark
```bash
cat >> ~/.bashrc <<!
export SPARK_HOME=/usr/local/spark
# pipx installs the binaries and executable scripts to this path
export PATH=\$PATH:\$HOME/.local/bin:\$SPARK_HOME/bin
!
source ~/.bashrc
```

we will then test the similar netcat application as we did for Flume, but this time with Spark Streaming.

I have downloaded that example from following link (however you need not do it, you can use the one from github repo)

> see [](https://archive.apache.org/dist/spark/docs/3.5.3/streaming-programming-guide.html#a-quick-example)

## in session #1

do the netcat test

```bash
su - hduser
netcat -lk 44444
```
> enter e.g. `Hello Spark, the word Hello should appear twice`

## in session #2
start spark streaming job

```bash
su - hduser
export SPARK_LOCAL_IP=127.0.0.1
$SPARK_HOME/bin/spark-submit ~/BigData/src/spark/network_wordcount.py localhost 44444
```

expected output in session #2:
> 
> Time: 2014-10-14 15:25:21
> 
> (Hello,2)<br>
> (Spark,1)<br>
> ...