#!/usr/bin/env python3
# call with:
# ~hduser/.local/bin/spark-submit \
#  --jars  ~/BigData/external_libs/mysql-connector-j-8.1.0.jar \
#  ~hduser/BigData/scripts/05/05f_spark_write_to_rdbms.py \
#  --host datanode1 --port 13306 --database <swdXX|itmXX> --user <swdXX|itmXX> --password <swdXX|itmXX>
#  --hive_table 

import argparse
from pyspark.sql import SparkSession

parser = argparse.ArgumentParser()

parser.add_argument("--database", required=True)
parser.add_argument("--host", default="datanode1")
parser.add_argument("--port", type=int, default=13306, help="MySQL port (default: 13306)")
parser.add_argument("--user", help="defaults to --database")
parser.add_argument("--password", help="defaults to --database")
parser.add_argument("--hive_table", default="studentsSpark")

args = parser.parse_args()

# initialize Spark Session
spark = SparkSession.builder \
    .appName("Hive_to_MySQL_Students") \
    .config("spark.sql.warehouse.dir", "hdfs://namenode:9000/user/hive/warehouse") \
    .enableHiveSupport() \
    .getOrCreate()

# read data from hive
hive_table = args.hive_table
print(f"read data from hive table '{hive_table}'...")
hive_df = spark.sql(f"SELECT * FROM {hive_table}")

# connection data
jdbc_url = "jdbc:mysql://"+args.host+":"+str(args.port)+"/"+args.database+"?useSSL=false&allowPublicKeyRetrieval=true"
db_properties = {
    "user": args.user,
    "password": args.password,
    "driver": "com.mysql.cj.jdbc.Driver"
}

target_mysql_table = "studentsMySQL"

print(f"Write data to MySQL table '{target_mysql_table}' in append mode ...")
# .mode("append") adds new data
# if you first want to purge the existing table, then use mode "overwrite".
hive_df.write.jdbc(
    url=jdbc_url,
    table=target_mysql_table,
    mode="append", 
    properties=db_properties
)

print("Export from Hive to MySQL successful!")

# properly close spark session
spark.stop()
