# BigData05 - spark RDBMS access

show how to use Spark for accessing RDBMS systems and transfer data between RDBMS and Hadoop

all actions done as `hduser`

We use python scripts, which is the easiest way to use spark

replace `<swdXX|itmXX>` with your own schema, e.g. swd01 or itm01
```bash
~hduser/.local/bin/spark-submit \
  --jars  ~/BigData/external_libs/mysql-connector-j-8.1.0.jar \
  ~hduser/BigData/scripts/05/05f_spark_read_from_rdbms_to_hdfs.py \
  --host datanode1 --port 13306 --database <swdXX|itmXX> --user <swdXX|itmXX> --password <swdXX|itmXX> \
  --hdfs_dir hdfs://namenode:9000/tmp/students
```

expected output in HDFS file system
```bash
hdfs dfs -ls /tmp/students
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
