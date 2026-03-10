# BigData04 - HBase bulk import

prepare a HDFS directory and copy a csv file there, which we want to bulk-load into hbase
```bash
hdfs dfs -mkdir -p /import/input
hdfs dfs -put ~/BigData/data/people.csv /import/input/
```

in the following command, it is correct that the definition is "importts.bulk.output" (without the letter `v`)
and not "importts.bulk.output"!

**IMPORTANT** For better readability a multi-line command is used here. The `\` MUST be the last character of the line, not even followed by a blank

```bash
hbase org.apache.hadoop.hbase.mapreduce.ImportTsv \
-Dimporttsv.columns=HBASE_ROW_KEY,id:name,property:job \
-Dimporttsv.separator=, -Dimportts.bulk.output=/import/output people \
hdfs://namenode:9000/import/input/people.csv
```

you can see, that in the background a MapReduce job is executed

expected output of `count`and `get`: 20000 rows total and row1 with data from "Eric Vogel".
```bash
hbase shell <<!
   count 'people'
   get 'people', 'row1'
   list_regions 'people'
!
```