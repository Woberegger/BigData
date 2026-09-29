#!/usr/bin/env python3
# call with:
# ~hduser/.local/bin/spark-submit --master yarn \
#  --deploy-mode client--jars \
#  ~/BigData/external_libs/mysql-connector-j-8.1.0.jar ~/BigData/src/spark/spark_db.py
#
# to check DB connect interactively...
# apt install default-mysql-client
# echo "ssl-verify-server-cert = off" >>/etc/mysql/conf.d/mysql.cnf # to not ask for certificate
# mysql --host=datanode1 --port=13306 --user=swd00 --password #--skip-ssl-verify-server-cert

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

# Spark Session mit Hive-Unterstützung
spark = SparkSession.builder \
    .appName("MySQL_to_Hive_Students") \
    .config("spark.sql.warehouse.dir", "hdfs://namenode:9000/user/hive/warehouse") \
    .enableHiveSupport() \
    .getOrCreate()

# Verbindungsdaten
jdbc_url = "jdbc:mysql://"+args.host+":"+str(args.port)+"/"+args.database+"?useSSL=false&allowPublicKeyRetrieval=true"
db_properties = {
    "user": args.user,
    "password": args.password,
    "driver": "com.mysql.cj.jdbc.Driver"
}

# Parallelisierung basierend auf der Spalte 'id'
# 3. Parameter für die Parallelisierung (Sqoop Mapper-Äquivalent)
# Um parallel zu lesen, benötigt Spark eine numerische/Datums-Spalte (z.B. die ID)
target_table = "studentsMySQL"
partition_column = "id"  # Sqoop: --split-by
lower_bound = "1"        # Minimaler Wert der ID
upper_bound = "1000000"  # Maximaler Wert der ID
num_partitions = "4"     # Sqoop: -m 4 (Anzahl der parallelen Tasks)

# 4. Daten über JDBC parallel einlesen
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

# 5. Daten im Hadoop HDFS speichern (Sqoop: --target-dir)
# Parquet wird für Hadoop 3.x dringend empfohlen (komprimiert, spaltenbasiert, extrem schnell)
hdfs_target_path = args.hdfs_dir

print(f"write data to HDFS: {hdfs_target_path}")
df.write \
    .mode("overwrite") \
    .parquet(hdfs_target_path)

print("Data successfully imported!")

# Spark Session sauber schließen
spark.stop()