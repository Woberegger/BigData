# BigData05 - install Sqoop

This document shows steps to install Sqoop 1.4.7 and configure the environment for use with Hadoop/Hive/HBase. Run the following commands as root where noted.

Install Sqoop under /usr/local and set ownership to the `hduser` account.

```bash
sudo -s
cd /usr/local
export SQOOP_VERSION=1.4.7
wget https://archive.apache.org/dist/sqoop/${SQOOP_VERSION}/sqoop-${SQOOP_VERSION}.bin__hadoop-2.6.0.tar.gz
tar -xzf sqoop-${SQOOP_VERSION}.bin__hadoop-2.6.0.tar.gz
ln -s sqoop-${SQOOP_VERSION}.bin__hadoop-2.6.0 sqoop
chown -R hduser:hadoop sqoop-${SQOOP_VERSION}.bin__hadoop-2.6.0
# gain again free space
rm sqoop-${SQOOP_VERSION}.bin__hadoop-2.6.0.tar.gz
```

Important: add a permission line to the Java policy file used by your JVM to avoid exceptions during Sqoop import/export operations.
Edit `/usr/lib/jvm/temurin-17-jdk-amd64/conf/security/java.policy` (path may vary for your JVM) and add the following permission inside a `grant { ... }` block:

```vim
permission javax.management.MBeanTrustPermission "register";
```

If this permission is not present you may encounter exceptions during Sqoop import/export.

Switch to the `hduser` account and add Sqoop environment variables to the user's shell profile.

```bash
su - hduser
cat >> ~/.bashrc <<!
export SQOOP_HOME=/usr/local/sqoop
export ACCUMULO_HOME=\$SQOOP_HOME   # just to get rid of a warning; not actually needed
export ZOOKEEPER_HOME=\$HADOOP_HOME/zookeeper  # just to get rid of a warning
export PATH=\$PATH:\$SQOOP_HOME/bin
!

source ~/.bashrc
```

Copy and configure the Sqoop configuration file and set required variables.

```bash
cd $SQOOP_HOME/conf
cp -p sqoop-env-template.sh sqoop-env.sh
```

Append (or replace the corresponding lines) in `sqoop-env.sh` to point to your Hadoop/HBase/Hive installations:

```bash
cat >>sqoop-env.sh <<!
export HADOOP_COMMON_HOME=/usr/local/hadoop
export HADOOP_MAPRED_HOME=/usr/local/hadoop/share/hadoop/mapreduce
export HBASE_HOME=/usr/local/HBase
export HIVE_HOME=/usr/local/hive
!
```

Create the `libjars` directory required by Sqoop to avoid warnings during data loading.

```bash
mkdir -p $SQOOP_HOME/libjars/
```

Run the Sqoop helper to finalize configuration (interactive script may copy connectors and set permissions).

```bash
$SQOOP_HOME/bin/configure-sqoop
```

Verify the installation by printing the Sqoop version.

```bash
sqoop version
```
## possible errors
>  ERROR cli.SqoopParser: Could not load required method of Parser: java.lang.NoSuchMethodException: org.apache.commons.cli.Option.addValueForProcessing(java.lang.String)

sqoop does not seem to work with latest hadoop, compiled with Java 17. The following howto might solve it, but currently not working
```bash
sudo -s
cd /usr/local
wget https://archive.apache.org/dist/commons/cli/binaries/commons-cli-1.2-bin.tar.gz
tar -xzvf commons-cli-1.2-bin.tar.gz commons-cli-1.2/commons-cli-1.2.jar
mv commons-cli-1.2/commons-cli-1.2.jar sqoop/lib/
echo "export SQOOP_USER_CLASSPATH=$SQOOP_HOME/lib/commons-cli-1.2.jar:\$SQOOP_USER_CLASSPATH" >>$SQOOP_HOME/conf/sqoop-env.sh
```

## Notes and next steps
- You may need to copy Hadoop MapReduce JARs into the Sqoop lib directory to avoid `ClassNotFound` exceptions when running imports/exports.
- After completing this installation, continue with the next script: `05b_sqoop_with_mysql.md` to test Sqoop with a MySQL backend.
