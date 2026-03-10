# BigData05 - install flume

Flume is used as tool to collect and aggregate large amounts of stream data (e.g. log data) from various sources and transfer it to HDFS.

## download and install Flume

```bash
sudo -s
cd /usr/local
export FLUME_VERSION=1.11.0
wget --no-check-certificate https://archive.apache.org/dist/flume/${FLUME_VERSION}/apache-flume-${FLUME_VERSION}-bin.tar.gz
tar -xzf apache-flume-${FLUME_VERSION}-bin.tar.gz
ln -s apache-flume-${FLUME_VERSION}-bin flume
chown -R hduser:hadoop apache-flume-${FLUME_VERSION}-bin flume
```

## set environment for Flume for hduser

```bash
su - hduser

cat >> ~/.bashrc <<!
export FLUME_HOME=/usr/local/flume
export PATH=\$PATH:\$FLUME_HOME/bin
if [ -z "\$CLASSPATH" ]; then
   export CLASSPATH=\$FLUME_HOME/lib/*
else
   export CLASSPATH=\$CLASSPATH:\$FLUME_HOME/lib/*
fi
!

source ~/.bashrc
```

## adapt Flume configuration by adapting the template files
```bash
su - hduser
cd $FLUME_HOME/conf
cp -p flume-env.sh.template flume-env.sh
cp -p flume-conf.properties.template flume-conf.properties
```

Either append to the end of the file or better replace in the file at the appropriate place (check if JAVA_HOME is correct).

```bash
cat >>flume-env.sh <<!
export JAVA_HOME=/usr/lib/jvm/temurin-11-jdk-$(dpkg --print-architecture)
# Flume Channels might show errors that they overflow, therefore set Java memory options a bit higher
export JAVA_OPTS="-Xms512m -Xmx1024m -Dcom.sun.management.jmxremote"
export FLUME_CLASSPATH="/usr/local/flume/lib/*"
!
```

## low-level check, if Flume works

```bash
flume-ng version
```

In case of the following error in one of the following tests, the versions of the Guava libs do not match.

> java.lang.NoSuchMethodError: com.google.common.base.Preconditions.checkArgument
> 
```bash
mv $FLUME_HOME/lib/guava-*.jar /tmp
ln -s $HADOOP_HOME/share/hadoop/hdfs/lib/guava-27.0-jre.jar $FLUME_HOME/lib/
```

## Next steps

Continue with scripts for various Flume tests for SeqGenerator, Netcat-API and possibly social media streaming.
