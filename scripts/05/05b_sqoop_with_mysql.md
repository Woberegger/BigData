# BigData05 - use sqoop with MySQL

We will use a MySQL installation on one of the datanodes, preferably `datanode1`.<br>
And then we will try to exchange data between Hive and a relational database (like MySQL) using Sqoop.

To allow Sqoop to access databases you need an appropriate JDBC connector - in our case for MySQL.

> **IMPORTANT:** MySQL objects are case-sensitive by default,<br>
> i.e. studentsMySQL != studentsmysql

Install the MySQL client (approx. 86 MB):

```bash
sudo apt install default-mysql-client
```

Switch to the `hduser` account.

```bash
su - hduser
```

For testing, connect to the MySQL Docker container on `datanode1`.
Important: the MySQL Docker container must forward its port to host port 13306; the native MySQL port is usually 3306.

Set connection environment variables (the example derives the MySQL user from the hostname):

```bash
export MYSQL_PORT=13306
export MYSQL_USER=$(echo ${HOSTNAME//bigdata})
export MYSQL_PASSWD=$MYSQL_USER
export DATABASE_NAME=$MYSQL_USER
export MYSQL_HOST=datanode1
~/BigData/scripts/grp02/grp02_mysql_testcall.sh $MYSQL_USER $MYSQL_HOST
```

The MySQL user needs a directory in HDFS; otherwise Sqoop operations may raise exceptions like "java.io.IOException: java.lang.ClassNotFoundException: students".

```bash
hdfs dfs -mkdir /user/${MYSQL_USER}
hdfs dfs -chmod 777 /user/${MYSQL_USER}
```

Create the test database and a `studentsMySQL` table in MySQL. Note: `entry_date` as DATE may cause issues with Sqoop export<br>
--> use VARCHAR for this field in the MySQL table.

```bash
mysql --ssl=FALSE -u $MYSQL_USER -D $DATABASE_NAME -h $MYSQL_HOST -P 13306 --password=$MYSQL_PASSWD <<EOF
CREATE DATABASE IF NOT EXISTS $DATABASE_NAME;
use $DATABASE_NAME;
CREATE TABLE IF NOT EXISTS studentsMySQL (
    id INT PRIMARY KEY,
    first_name VARCHAR(80) NOT NULL,
    last_name VARCHAR(80) NOT NULL,
    entry_date VARCHAR(20) NOT NULL,
    course VARCHAR(80) NOT NULL
);
show tables;
EOF
```

Start HiveServer2 in a separate shell if it is not running yet (we set the Thrift port to 10000 here):

```bash
hive --service hiveserver2 --hiveconf hive.server2.thrift.port=10000
```

Create an identical table in Hive (database `fh`) and prepare a table for data that will be imported back from MySQL.

```bash
export HIVE_CONNECT_STRING=localhost:10000
beeline -u jdbc:hive2://${HIVE_CONNECT_STRING} scott tiger <<!
   set hive.execution.engine=mr;
   set hive.metastore.warehouse.dir;
   create database if not exists fh;
   show databases;
   use fh;
   show tables;
   -- copy this table from Hive to MySQL
   DROP table students;
   CREATE TABLE IF NOT EXISTS students( id INT , first_name STRING, last_name STRING, entry_date DATE, course STRING)
      COMMENT 'Students to sync with mySQL'
      ROW FORMAT DELIMITED FIELDS TERMINATED BY ',';
   describe students;
   -- and back into this table from MySQL
   DROP table studentsFromMySQL;
   CREATE TABLE IF NOT EXISTS studentsFromMySQL ( id INT , first_name STRING, last_name STRING, entry_date DATE, course STRING)
   COMMENT 'Students to sync with MySQL';
!
```

You can either upload a CSV file into HDFS or use Hive's `LOAD DATA LOCAL INPATH` to load a local file into the `students` table.

```bash
# optional: hdfs dfs -put BigData/data/students.csv /tmp/
beeline -u jdbc:hive2://${HIVE_CONNECT_STRING} scott tiger <<!
   use fh;
   LOAD DATA LOCAL INPATH '/home/hduser/BigData/data/students.csv' OVERWRITE INTO TABLE students;
   select * from students limit 10;
!
```

You may need to copy the Hadoop MapReduce JAR files into the Sqoop lib directory to avoid ClassNotFound exceptions. Sqoop also generates a class JAR (e.g. `students.jar`) for imports that must be on the classpath—set `--bindir` accordingly (for example `/usr/local/hadoop/share/hadoop/common/lib`).

```bash
cp -p /usr/local/hadoop/share/hadoop/mapreduce/*.jar $SQOOP_HOME/lib/
```

List available databases and tables in the MySQL instance to verify connectivity.

```bash
sqoop-list-databases --connect jdbc:mysql://${MYSQL_HOST}:${MYSQL_PORT} --username $MYSQL_USER --password ${MYSQL_PASSWD}
sqoop-list-tables --connect jdbc:mysql://${MYSQL_HOST}:${MYSQL_PORT}/${DATABASE_NAME} --username $MYSQL_USER --password ${MYSQL_PASSWD}
```

Export data from Hive to MySQL using Sqoop (exporting is less common but possible).
Use `--num-mappers 1` to limit parallel connections.

```bash
sqoop export --connect jdbc:mysql://${MYSQL_HOST}:${MYSQL_PORT}/${DATABASE_NAME}  \
   --table studentsMySQL --username $MYSQL_USER --password ${MYSQL_PASSWD}  \
   --export-dir /user/hive/warehouse/fh.db/students --num-mappers 1  \
   --driver com.mysql.cj.jdbc.Driver  --input-fields-terminated-by ',' \
   --input-lines-terminated-by '\n' --bindir /usr/local/hadoop/share/hadoop/common/lib
```

Verify in MySQL that the exported data is present.

```bash
mysql --ssl=FALSE -u $MYSQL_USER -D $DATABASE_NAME -h $MYSQL_HOST -P 13306 --password=$MYSQL_PASSWD <<EOF
use $DATABASE_NAME;
SELECT * FROM studentsMySQL LIMIT 10;
EOF
```

To test the other direction (import from MySQL into Hive), remove any previous HDFS target directory from earlier attempts.

```bash
hdfs dfs -rm -R /user/hduser/studentsMySQL 2>/dev/null
```

You may encounter errors because the Java VM disallows access to the Derby JAR used by Hive's default metastore (e.g. `/usr/local/hive/lib/derby-10.14.2.0.jar`), causing exceptions such as `NoClassDefFoundError: Could not initialize class org.apache.derby.jdbc.EmbeddedDriver`.

To fix permission issues, append the contents of `../grp02/grp02_java_policy_to_add.txt` at the start of `$JAVA_HOME/lib/security/default.policy` (for example `/usr/lib/jvm/temurin-11-jdk-amd64/lib/security/default.policy`), or add the following lines to the generic `grant { ... }` section at the end of the file:

- permission javax.management.MBeanTrustPermission "register";
- permission org.apache.derby.security.SystemPermission "engine", "usederbyinternals";

**IMPORTANT:** When using Derby as the Hive metastore (the default), Derby does not allow concurrent access. Stop HiveServer2 before running a Sqoop import. If you use MySQL as Hive's metastore, this is not necessary.

Also ensure `-m 1` or `--num-mappers 1` is set for Sqoop imports so only one connection is opened to MySQL.

Import data from MySQL into Hive using Sqoop (creates `studentsFromMySQL` in database `fh`):

```bash
sqoop import --connect jdbc:mysql://${MYSQL_HOST}:${MYSQL_PORT}/${DATABASE_NAME}  --username $MYSQL_USER --password ${MYSQL_PASSWD} \
   --table studentsMySQL  --driver com.mysql.cj.jdbc.Driver  --hive-import --hive-database fh \
   --hive-table studentsFromMySQL --hive-overwrite -m 1  \
   --bindir /usr/local/hadoop/share/hadoop/common/lib
```

If the above command fails, as an alternative import the MySQL data into HDFS and then create an external Hive table pointing to that HDFS directory. External tables do not support constraints.

Sometimes `--query` must be used instead of `--table` to control delimiters and query behavior. The example below fetches rows from MySQL into an HDFS target directory as text files.

```bash
sqoop import --connect jdbc:mysql://${MYSQL_HOST}:${MYSQL_PORT}/${DATABASE_NAME}  --username $MYSQL_USER --password ${MYSQL_PASSWD} \
   --query "SELECT * FROM studentsMySQL WHERE \$CONDITIONS" --split-by , --driver com.mysql.cj.jdbc.Driver \
   --target-dir /user/hduser/studentsFromFile --fields-terminated-by , --as-textfile \
   -m 1 --bindir /usr/local/hadoop/share/hadoop/common/lib
# Verify data
hdfs dfs -cat /user/hduser/studentsFromFile/part* | head
```

Verify contents in Hive using Beeline.

```bash
export HIVE_CONNECT_STRING=localhost:10000
beeline -u jdbc:hive2://${HIVE_CONNECT_STRING} scott tiger <<!
   set hive.execution.engine=mr;
   set hive.metastore.warehouse.dir;
   use fh;
   
   CREATE EXTERNAL TABLE IF NOT EXISTS studentsFromFile (
    id INT,
    first_name string,
    last_name string,
    entry_date DATE,
    course string)
    COMMENT 'StudentsAsHDFSFile'
    ROW FORMAT DELIMITED
    FIELDS TERMINATED BY ','
    STORED AS TEXTFILE
    LOCATION '/user/hduser/studentsFromFile';
   -- what we have loaded from Sqoop into HDFS 
   SELECT * FROM studentsFromFile LIMIT 10;
   -- what we have loaded from Sqoop directly into hive 
   SELECT * FROM studentsFromMySQL LIMIT 10;
!
```

If both tables are empty, the Sqoop import did not work — check Sqoop output for errors. To retry, remove the HDFS directory first:

```bash
hdfs dfs -rm -R /user/hduser/studentsMySQL #(or /user/hduser/studentsFromFile)
```
