# BigData05 - use sqoop with locally installed MySQL container

Accessing databases with Sqoop requires an appropriate JDBC connector for MySQL (for example).
> Note: MySQL object names are case-sensitive by default, i.e. studentsMySQL != studentsmysql

Switch to the `hduser` account and prepare HDFS directories for the MySQL user.

> **Important:** the MySQL user needs a directory in HDFS; otherwise you'll get an exception like<br>
> "java.io.IOException: java.lang.ClassNotFoundException: students"

```bash
su - hduser
export MYSQL_USER=root
hdfs dfs -mkdir /user/${MYSQL_USER}
hdfs dfs -chmod 777 /user/${MYSQL_USER}
```

Prepare Docker and MySQL environment variables as root.

```bash
sudo -s
export DOCKER_CONTAINERNAME=swdMysql
export DATABASE_NAME=swd
```

Check whether the container "swdMysql" is running; if not, start it with `docker start swdMysql`.

```bash
docker ps
```

Connect to the Docker container that we created in Exercise 4 for the metadata store (for testing).

```bash
docker exec -it -u mysql ${DOCKER_CONTAINERNAME} /bin/bash
```

You can also pass a here-document to the Docker container non-interactively using `-i --tty=false`.

```bash
docker exec -i --tty=false -u mysql ${DOCKER_CONTAINERNAME} /bin/bash <<EOF
# The following block runs inside the container (root MySQL password: "my-secret-pw")
mysql -u root -pmy-secret-pw <<!

CREATE DATABASE IF NOT EXISTS $DATABASE_NAME;
show databases;
use $DATABASE_NAME;

CREATE TABLE IF NOT EXISTS studentsMySQL (
    id INT PRIMARY KEY,
    first_name VARCHAR(80) NOT NULL,
    last_name VARCHAR(80) NOT NULL,
    entry_date DATE,
    course VARCHAR(80) NOT NULL
);
show tables;
!
EOF
```

Now create an identical table in Hive.

```bash
su - hduser
export HIVE_CONNECT_STRING=localhost:10000
beeline -u jdbc:hive2://${HIVE_CONNECT_STRING} scott tiger <<!
   set hive.execution.engine=mr;
   set hive.metastore.warehouse.dir;
   create database if not exists fh;
   show databases;
   use fh;
   show tables;
   -- we will copy this table from Hive to MySQL
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

Generate a CSV file with the required test data (for example using [Datagenerator](https://generatedata.com/)).<br>
A pre-generated file is available in the github repo under `data/students.csv`.
You may need to post-process the generated data:
- Split first and last name (example: replace space with comma): `sed -i 's/ /,/g' students.csv`
- Adjust date formats if necessary (not required for our basic test).

Load the CSV into the Hive `students` table using LOCAL INPATH (or put the file into HDFS manually).

```bash
# optional: hdfs dfs -put BigData/data/students.csv /tmp/
beeline -u jdbc:hive2://${HIVE_CONNECT_STRING} scott tiger <<!
   use fh;
   LOAD DATA LOCAL INPATH '/home/hduser/BigData/data/students.csv' OVERWRITE INTO TABLE students;
   select * from students limit 10;
!
```

It appears the MapReduce JAR files must be copied into the Sqoop lib directory to avoid `ClassNotFound` exceptions.
Sqoop also generates a class JAR (e.g. `students.jar`) for imports that must be on the classpath — set `--bindir` accordingly
(for example `/usr/local/hadoop/share/hadoop/common/lib`).

```bash
cp -p /usr/local/hadoop/share/hadoop/mapreduce/*.jar $SQOOP_HOME/lib/
```

Set database and connection environment variables for Sqoop. Note: port forwarding for the MySQL Docker container commonly maps host port 13306 to container's 3306.

```bash
export DATABASE_NAME=swd
export MYSQL_PORT=13306
export MYSQL_USER=root
export MYSQL_PASSWD=my-secret-pw
export DOCKER_CONTAINERNAME=swdMysql
```

List databases and tables in the MySQL instance to verify connectivity.

```bash
sqoop-list-databases --connect jdbc:mysql://localhost:${MYSQL_PORT} --username $MYSQL_USER --password ${MYSQL_PASSWD}
sqoop-list-tables --connect jdbc:mysql://localhost:${MYSQL_PORT}/${DATABASE_NAME} --username $MYSQL_USER --password ${MYSQL_PASSWD}
```

Export data from Hive to MySQL using Sqoop (exporting is less common but possible).<br>
`-m 1` sets number of mappers to 1.

```bash
sqoop export --connect jdbc:mysql://localhost:${MYSQL_PORT}/${DATABASE_NAME}  \
   --table studentsMySQL --username $MYSQL_USER --password ${MYSQL_PASSWD}  \
   --export-dir /user/hive/warehouse/fh.db/students --num-mappers 1  \
   --driver com.mysql.cj.jdbc.Driver  --input-fields-terminated-by ',' \
   --input-lines-terminated-by '\n' --bindir /usr/local/hadoop/share/hadoop/common/lib
```

Check in MySQL whether the data arrived.

```bash
sudo docker exec -i --tty=false -u mysql ${DOCKER_CONTAINERNAME} /bin/bash <<EOF
mysql -u $MYSQL_USER -p${MYSQL_PASSWD} <<!
use $DATABASE_NAME;
SELECT * FROM studentsMySQL LIMIT 10;
!
EOF
```

To import data from MySQL into Hive, first remove any previous HDFS target directory from earlier attempts.

```bash
hdfs dfs -rm -R /user/hduser/studentsMySQL 2>/dev/null
```

You may encounter errors caused by the Java VM refusing access to Derby's jar file (e.g. `/usr/local/hive/lib/derby-10.14.2.0.jar`) leading to a `NoClassDefFoundError: Could not initialize class org.apache.derby.jdbc.EmbeddedDriver`.

If you use Derby as Hive metastore (default), note that Derby does not allow concurrent access; therefore stop the Hive server before performing Sqoop import. If you use MySQL as metastore, this is not necessary.

To grant permissions when Derby causes access issues, append the contents of `../grp02/grp02_java_policy_to_add.txt` to the start of the `$JAVA_HOME/lib/security/default.policy` file (e.g. `/usr/lib/jvm/temurin-11-jdk-amd64/lib/security/default.policy`) or add these lines into the general `grant { ... }` section at the end of the file:

- permission javax.management.MBeanTrustPermission "register";
- permission org.apache.derby.security.SystemPermission "engine", "usederbyinternals";

Warning: When using Derby as the Hive metastore, concurrent access is not allowed; stop HiveServer2 before running Sqoop import. If using MySQL as metastore, this is not required.

Run Sqoop import from MySQL into Hive (import and create `studentsFromMySQL` table in the `fh` Hive database):

```bash
sqoop import --connect jdbc:mysql://localhost:${MYSQL_PORT}/${DATABASE_NAME}  --username $MYSQL_USER --password ${MYSQL_PASSWD} \
   --table studentsMySQL  --driver com.mysql.cj.jdbc.Driver  --hive-import --hive-database fh \
   --hive-table studentsFromMySQL --hive-overwrite --num-mappers 1  \
   --bindir /usr/local/hadoop/share/hadoop/common/lib
```

If that command fails, alternatively import the data into HDFS first and then create an external Hive table that points to the HDFS directory. External tables do not support constraints.

Sometimes `--query` must be used instead of `--table` to control delimiters and query behavior. The example below fetches rows from MySQL into an HDFS target directory as text files.

```bash
sqoop import --connect jdbc:mysql://localhost:${MYSQL_PORT}/${DATABASE_NAME}  --username $MYSQL_USER --password ${MYSQL_PASSWD} \
   --query "SELECT * FROM studentsMySQL WHERE \$CONDITIONS" --split-by , --driver com.mysql.cj.jdbc.Driver \
   --target-dir /user/hduser/studentsFromFile --fields-terminated-by , --as-textfile \
   --num-mappers 1 --bindir /usr/local/hadoop/share/hadoop/common/lib
# Verify data
hdfs dfs -cat /user/hduser/studentsFromFile/part* | head
```

If you are using Derby as the Hive metastore, restart HiveServer2 afterwards to make Beeline work:

```bash
# hive --service hiveserver2 &
```

Verify contents from Beeline (connect string as before).

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
    
   SELECT * FROM studentsFromMySQL LIMIT 10;
!
```

If the table is empty, the Sqoop import did not work — check Sqoop output for errors. To retry, first remove the HDFS directory again:

```bash
hdfs dfs -rm -R /user/hduser/studentsMySQL #(or /user/hduser/studentsFromFile)
```
