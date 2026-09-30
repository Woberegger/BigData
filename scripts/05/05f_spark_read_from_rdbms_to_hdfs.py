#!/usr/bin/env python3
# call with:
# ~hduser/.local/bin/spark-submit \
#  --jars  ~/BigData/external_libs/mysql-connector-j-8.1.0.jar \
#  ~hduser/BigData/scripts/05/05f_spark_read_from_rdbms_to_hdfs.py \
#  --host datanode1 --port 13306 --database <swdXX|itmXX> --user <swdXX|itmXX> --password <swdXX|itmXX> \
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

if args.user is None:
   args.user = args.database
 
if args.password is None:
   args.password = args.database

# connection data
jdbc_url = "jdbc:mysql://"+args.host+":"+str(args.port)+"/"+args.database+"?useSSL=false&allowPublicKeyRetrieval=true"
db_properties = {
    "user": args.user,
    "password": args.password,
    "driver": "com.mysql.cj.jdbc.Driver"
}

# parallelising on column 'id' (needs to be a numeric or date column)
# (used as Sqoop Mapper equivalent)
target_table = "studentsMySQL"
partition_column = "id"  # Sqoop: --split-by
lower_bound = "1"        # Minimum value of ID
upper_bound = "1000000"  # Maximum value of ID
num_partitions = "4"     # Sqoop: -m 4 (number of parallel tasks)

# read data using JDBC
print(f"read data from table {target_table}...")
df = spark.read.jdbc(
    url=jdbc_url,
    table=target_table,
    column=partition_column,
    lowerBound=lower_bound,
    upperBound=upper_bound,
    numPartitions=num_partitions,
    properties=db_properties
)

# store data to HDFS (Sqoop: --target-dir)
# 'parquet' mode is highly recommended for Hadoop 3.x (compressed, column-oriented, very fast)
hdfs_target_path = args.hdfs_dir

print(f"write data to HDFS: {hdfs_target_path}")
df.write \
    .mode("overwrite") \
    .parquet(hdfs_target_path)

print("Data successfully imported!")

# Spark Session sauber schließen
spark.stop()