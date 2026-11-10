# BigData05 - spark RDBMS access

show how to use Spark for accessing RDBMS systems and transfer data between RDBMS and Hadoop

all actions done as `hduser`

We use python scripts, which is the easiest way to use spark

the proper user `<swdXX|itmXX>`, e.g. swd01 or itm01, is extracted from the machine's hostname.

first fill some test data into MySQL source table `studentsMySQL` (IMPORTANT: only necessary, when not yet done with Nifi task):

```bash
export MYSQL_USER=$(echo ${HOSTNAME//bigdata})
export MYSQL_PASSWD=$MYSQL_USER
export DATABASE_NAME=$MYSQL_USER
mysql --ssl=FALSE -u $MYSQLUSER -D $DATABASE_NAME  -h datanode1 -P 13306 --password=$MYSQL_PASSWD < ~/BigData/scripts/05/insertstudentsMySQL.sql
```

and then call the python task to read the data from RDBMS to HDFS
```bash
export MYSQL_USER=$(echo ${HOSTNAME//bigdata})
export MYSQL_PASSWD=$MYSQL_USER
export DATABASE_NAME=$MYSQL_USER
~hduser/.local/bin/spark-submit \
  --jars  ~/BigData/external_libs/mysql-connector-j-8.1.0.jar \
  ~hduser/BigData/scripts/05/05f_spark_read_from_rdbms_to_hdfs.py \
  --host datanode1 --port 13306 --database $DATABASE_NAME --user $MYSQL_USER --password $MYSQL_PASSWD \
  --hdfs_dir hdfs://namenode:9000/tmp/students
```

expected output in HDFS file system in binary [Parquet](https://de.wikipedia.org/wiki/Apache_Parquet) output format.<br>
Beside the empty "_SUCCESS" file it should find a file named "part-..."

```bash
hdfs dfs -ls /tmp/students/
```

## optionally show data in Hive external table
we simply can visualize the data as external table in Hive

(in other session start Hive, if it should not yet be running)
```bash
hive --service hiveserver2 --hiveconf hive.server2.thrift.port=10000
```

```bash
export HIVE_CONNECT_STRING=localhost:10000
beeline --verbose -u jdbc:hive2://$HIVE_CONNECT_STRING scott tiger <<!
DROP TABLE IF EXISTS StudentsSpark;
-- the entry_date column should be string, as date fields cannot easily be mapped between MySQL and hive
CREATE EXTERNAL TABLE IF NOT EXISTS StudentsSpark (
    id         INT,
    first_name STRING,
    last_name  STRING,
    entry_date STRING,
    course     STRING
)
STORED AS PARQUET
LOCATION '/tmp/students';
--
SELECT * FROM StudentsSpark;
!
```

## opposite way: read from Hive to MySql RDBMS
The other direction is less common, but would generally work as well, when versions of Hive and Spark match.<br>
However in our setup we use Hive version 4.1., whereas the Hive libraries in /usr/local/spark/jars/hive-* are assume version 2.3, which uses different metadata schema of hive, so it cannot read the table's data correctly (e.g. column DB_NAME is not present in new metadata definitions).<br>

For writing to MySQL it may be necessary to not pass the JDBC connector using `--jars`, but directly copy it to the spark
jars directory.

```bash
sudo cp ~/BigData/external_libs/mysql-connector-j-8.1.0.jar $SPARK_HOME/jars/
```

but as stated above, still the following call does not work, but raises the exception as below:
```bash
export MYSQL_USER=$(echo ${HOSTNAME//bigdata})
export MYSQL_PASSWD=$MYSQL_USER
export DATABASE_NAME=$MYSQL_USER
~hduser/.local/bin/spark-submit \
  ~hduser/BigData/scripts/05/05g_spark_write_to_rdbms.py \
  --host datanode1 --port 13306 --database $DATABASE_NAME --user $MYSQL_USER --password $MYSQL_PASSWD \
  --hive_table studentsSpark
```

> javax.jdo.JDOException: Exception thrown when executing query : SELECT 'org.apache.hadoop.hive.metastore.model.>MTableColumnStatistics' AS `NUCLEUS_TYPE`,`A0`.`AVG_COL_LEN`,`A0`.`COLUMN_NAME`,`A0`.`COLUMN_TYPE`,`A0`.`DB_NAME`,`A0`.>`BIG_DECIMAL_HIGH_VALUE`,`A0`.`BIG_DECIMAL_LOW_VALUE`,`A0`.`DOUBLE_HIGH_VALUE`,`A0`.`DOUBLE_LOW_VALUE`,`A0`.`LAST_ANALYZED`,>`A0`.`LONG_HIGH_VALUE`,`A0`.`LONG_LOW_VALUE`,`A0`.`MAX_COL_LEN`,`A0`.`NUM_DISTINCTS`,`A0`.`NUM_FALSES`,`A0`.`NUM_NULLS`,`A0`.>`NUM_TRUES`,`A0`.`TABLE_NAME`,`A0`.`CS_ID` FROM `TAB_COL_STATS` `A0` WHERE `A0`.`DB_NAME` = ''
>NestedThrowables:
>java.sql.SQLSyntaxErrorException: Unknown column 'A0.DB_NAME' in 'field list'


## Trouble shooting
Usually there might be a problem with SSL-support, for that we pass
`useSSL=falsea&llowPublicKeyRetrieval=true` to the JDBC connector. If you still get an exception, you can try interactive connection

```bash
apt install -y default-mysql-client
echo "ssl-verify-server-cert = off" >>/etc/mysql/conf.d/mysql.cnf # to not ask for certificate
# parameter --skip-ssl-verify-server-cert should not be necessary with above setting in mysql.cnf
mysql --host=datanode1 --port=13306 --user=<swdXX|itmXX> --password #--skip-ssl-verify-server-cert
```
