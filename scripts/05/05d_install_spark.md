# BigData05 - install spark

we install spark to see, how processing of streaming data works with Spark Streaming.<br>
Spark can also be used to read data from RDBMS systems, so we use it as replacement for outdated [Sqoop](https://sqoop.apache.org/)

```bash
sudo -s
cd /usr/local
export SPARK_VERSION=4.2.0
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

And then the "pyspark" package (*IMPORTANT:* as user `hduser` and not as root, because pipx installs the binaries and executable scripts to the home directory of the user into path ~/.local/bin)
```bash
su - hduser
# IMPORTANT: set $TMPDIR, otherwise it uses /tmp, which is a too small partition to take all pyspark installation files
export TMPDIR=~/tmp
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

continue with script 05e_spark_streaming.md