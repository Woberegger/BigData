hdfs dfs -mkdir -p /import/input
hdfs dfs -put ~/BigData/data/people.csv /import/input/

# im folgenden Befehl ist es korrekt, dass die Definition "importts.bulk.output" und nicht "importtsv.bulk.output" heisst!
hbase org.apache.hadoop.hbase.mapreduce.ImportTsv \
-Dimporttsv.columns=HBASE_ROW_KEY,id:name,property:job \
-Dimporttsv.separator=, -Dimportts.bulk.output=/import/output people \
hdfs://namenode:9000/import/input/people.csv
# man sieht, dass im Hintergrund ein MapReduce Job ausgeführt wird

# erwartete Ausgabe 20000 rows gesamt und row1 mit Daten von "Eric Vogel".
hbase shell <<!
   count 'people'
   get 'people', 'row1'
   list_regions 'people'
!