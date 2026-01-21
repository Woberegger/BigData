sudo -s
cd /usr/local
export SPARK_VERSION=3.5.3
wget https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop3.tgz
tar -xzf spark-${SPARK_VERSION}-bin-hadoop3.tgz
ln -s spark-${SPARK_VERSION}-bin-hadoop3 spark
rm spark-${SPARK_VERSION}-bin-hadoop3.tgz # to save space
chown -R hduser:hadoop spark*
# am einfachsten ist wohl, Spark Commandos in Python zu erstellen, daher wird pipx als Python-Paketverwaltung installiert
apt install pipx
# und danach das Paket "pyspark" (WICHTIG: als user "hduser")
su - hduser
pipx install pyspark

cat >> ~/.bashrc <<!
export SPARK_HOME=/usr/local/spark
# pipx installs the binaries and executable scripts to this path
export PATH=\$PATH:\$HOME/.local/bin:\$SPARK_HOME/bin
!
source ~/.bashrc

# und dann zum Test eine netcat-Applikation
SPARK_VERSION=3.5.3
siehe https://archive.apache.org/dist/spark/docs/${SPARK_VERSION}/streaming-programming-guide.html#a-quick-example
#
export SPARK_LOCAL_IP=127.0.0.1
cd ~/BigData
git pull
# in Session 1
netcat -lk 9999

$SPARK_HOME/bin/spark-submit ~/BigData/src/spark/network_wordcount.py localhost 9999