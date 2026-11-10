#!/usr/bin/env python3
# call with:
# ~hduser/.local/bin/spark-submit \
#  --jars  ~/BigData/external_libs/mysql-connector-j-8.1.0.jar \
#  ~hduser/BigData/scripts/05/05f_spark_write_to_rdbms.py \
#  --host datanode1 --port 13306 --database <swdXX|itmXX> --user <swdXX|itmXX> --password <swdXX|itmXX>
#  --hdfs_dir hdfs://namenode:9000/tmp/students

import argparse
from pyspark.sql import SparkSession

parser = argparse.ArgumentParser()

parser.add_argument("--hdfs_dir", default="hdfs://namenode:9000/tmp/students")
parser.add_argument("--database", required=True)
parser.add_argument("--host", default="datanode1")
parser.add_argument("--port", type=int, default=13306, help="MySQL port (default: 13306)")
parser.add_argument("--user", help="defaults to --database")
parser.add_argument("--password", help="defaults to --database")

args = parser.parse_args()
hdfs_path=args.hdfs_dir

# initialize Spark Session
spark = SparkSession.builder \
    .appName("HDFS_Parquet_to_MySQL_Students") \
    .getOrCreate()

# read data from HDFS directory, i.e. external hive table
print(f"read data from external hive table under path '{hdfs_path}'...")
df = spark.read.parquet(hdfs_path)

df.show()
df.printSchema()

# connection data
jdbc_url = "jdbc:mysql://"+args.host+":"+str(args.port)+"/"+args.database+"?useSSL=false&allowPublicKeyRetrieval=true"
db_properties = {
    "user": args.user,
    "password": args.password,
    "driver": "com.mysql.cj.jdbc.Driver"
}

target_mysql_table = "studentsMySQL"

print(f"Write data to MySQL table '{target_mysql_table}' in overwrite mode (as otherwise we would have duplicate keys) ...")
# .mode("append") adds new data
# if you first want to purge the existing table, then use mode "overwrite".
df.write.jdbc(
    url=jdbc_url,
    table=target_mysql_table,
    mode="overwrite", 
    properties=db_properties
)

print("Export from HDFS to MySQL successful!")

# properly close spark session
spark.stop()
