# BigData04 - install and configure Hive

## install and configure Hive

```bash
# If you need "--no-check-certificate" with wget, it's better to do the following beforehand to have proper certificates
sudo -s
update-ca-certificates -f
```

Attention: Make sure your Hadoop version is compatible with the Hive version - see [Hive Downloads](https://hive.apache.org/general/downloads/)

*Note*: Unfortunately the information there is incorrect. It's better to use the latest version 4.x.<br>
Hive 3.1.3 does not seem to work with our Hadoop version. Version 4.0.1 has been tested and works with Hadoop 3.3.6.<br>
Versions 4.0.1 and 4.1.0 should work with Hadoop 3.4.1.

```bash
cd /usr/local
export HIVE_VERSION=4.0.1
# We should not use 4.1.0, as it was compiled with Java17, so we would need an additional Java version for that, which differs from HDFS's Java
# If the certificate is not accepted (although we called update-ca-certificates), add parameter: --no-check-certificate
wget https://archive.apache.org/dist/hive/hive-${HIVE_VERSION}/apache-hive-${HIVE_VERSION}-bin.tar.gz

tar -xzf apache-hive-${HIVE_VERSION}-bin.tar.gz
ln -s /usr/local/apache-hive-${HIVE_VERSION}-bin /usr/local/hive
```

Change ownership of our hive installation directory

```bash
chown -R hduser:hadoop /usr/local/*hive*
```

### Hive settings as "hduser"
Connect as hduser (and do all following actions as this user)

```bash
su - hduser
cat >>~/.bashrc <<!
export HIVE_HOME=/usr/local/hive
export HCAT_HOME=\$HIVE_HOME/hcatalog
export PATH=\$PATH:\$HIVE_HOME/bin
# To prevent "java.lang.OutOfMemoryError", this error is difficult to trace when it occurs
export HADOOP_HEAPSIZE=2048
!
```

Activate changes, which we did to `.bashrc`

```bash
source ~/.bashrc
```

To be sure, we update the data from the repository, because we'll copy some files from there later
```bash
cd ~/BigData
git pull
```

Start HADOOP if not running yet
```bash
start-dfs.sh
```

### Create HDFS directories for Hive with proper permissions

```bash
hdfs dfs -mkdir -p /tmp/hive-jars
hdfs dfs -mkdir -p /user/hduser/.hiveJars
hdfs dfs -mkdir -p /user/hive/warehouse
hdfs dfs -mkdir -p /user/hduser/hive_external
# Normally "g+w" is sufficient, but if Hive connects as "anonymous", permissions need to be "a+w"
hdfs dfs -chmod a+w /tmp /tmp/hive-jars /user/hive/warehouse /user/hduser/hive_external /user/hduser/.hiveJars
```

### Adapt hive-site.xml

Be careful not to copy a configuration file from a different version, as they might not be compatible.

```bash
cd /usr/local/hive/conf
cp hive-default.xml.template hive-site.xml
# Since the configuration requires many settings and the probability of error is high, please use the checked-in script!
cp ~/BigData/scripts/04/hive-site.xml .
# ATTENTION!!! However, username and password must be changed in the script so each user has their own schema
HiveUserName=$(echo ${HOSTNAME//bigdata}hive)
sed -i "s/swd00hive/${HiveUserName}/g" hive-site.xml
```

### Hive install troubleshooting

#### Fix version compatibility issues

If you get the following error, the versions of Hadoop's and Hive's `guava` don't match, even though the download page says otherwise:

> `java.lang.NoSuchMethodError` - see [fix](https://issues.apache.org/jira/browse/HIVE-22915)

```bash
mv $HIVE_HOME/lib/guava-22.0.jar $HIVE_HOME/lib/guava-22.0.jar.wrong_version
ln -s $HADOOP_HOME/share/hadoop/hdfs/lib/guava-27.0-jre.jar $HIVE_HOME/lib/
```

#### Fix log4j warnings

Remove log4j warnings by moving the following jar file to a different name:
```bash
mv $HIVE_HOME/lib/log4j-slf4j-impl-2.18.0.jar $HIVE_HOME/lib/log4j-slf4j-impl-2.18.0.jar.wrong_version
```

## Test Hive

generic check, if hive command works
```bash
hive
```

### Hive call Troubleshooting

#### special characters in hive-site.xml
If there are errors, check the hive-site.xml file again. In some versions of the default file,
there is the following error that needs to be fixed manually
(special characters in comments for property e.g. hive.txn.xlock.iow):

> Caused by: com.ctc.wstx.exc.WstxParsingException: Illegal character entity: expansion character (code 0x8
> at [row,col,system-id]: [3221,96,"file:/usr/local/apache-hive-3.1.3-bin/conf/hive-site.xml"]

#### errors popping up later in beeline

Sometimes the first commands work fine and then suddenly there are errors in beeline.

See [](https://issues.apache.org/jira/browse/HIVE-21302) - change the following 2 entries in hive-site.xml:

```xml
<property>
   <name>datanucleus.schema.autoCreateAll</name>
   <value>true</value>
   <description>creates necessary schema on a startup if one doesn't exist.</description>
</property>
<property>
   <name>hive.metastore.schema.verification</name>
   <value>false</value>
</property>
```

## Next Steps

Continue with script `04h_hive_metastore_mysql.md` (preferred)<br>
or if using a local metastore, use `local_mysql_docker/04f_install_mysql_docker.md`
