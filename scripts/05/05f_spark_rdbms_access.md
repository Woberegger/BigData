# BigData05 - spark RDBMS access

show how to use Spark for accessing RDBMS systems and transfer data between RDBMS and Hadoop

all actions done as `hduser`

We use python scripts, which is the easiest way to use spark

the proper user `<swdXX|itmXX>`, e.g. swd01 or itm01, is extracted from the machine's hostname.
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

expected output in HDFS file system in binary [Parquet](https://de.wikipedia.org/wiki/Apache_Parquet) output format.
```bash
hdfs dfs -ls /tmp/students/
```

## optionally show data in Hive external table
we simply can visualize the data as external table in Hive

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
!
```

## Trouble shooting
Usually there might be a problem with SSL-support, for that we pass
`useSSL=falsea&llowPublicKeyRetrieval=true` to the JDBC connector. If you still get an exception, you can try interactive connection

```bash
apt install -y default-mysql-client
echo "ssl-verify-server-cert = off" >>/etc/mysql/conf.d/mysql.cnf # to not ask for certificate
# parameter --skip-ssl-verify-server-cert should not be necessary with above setting in mysql.cnf
mysql --host=datanode1 --port=13306 --user=<swdXX|itmXX> --password #--skip-ssl-verify-server-cert
```
