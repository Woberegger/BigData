# BigData04 - Hive commands preparation

Start hdfs, if it should not be running yet
```bash
start-dfs.sh
```

additionally start hiveserver (in foreground), if you did not yet do so in previous howto
```bash
hive --service hiveserver2 --hiveconf hive.server2.thrift.port=10000
```

open new terminal session.

prepare directories for external hive data in HDFS

```bash
hdfs dfs -mkdir -p /user/hduser/hive_external/adr
hdfs dfs -mkdir -p /user/hduser/hive_external/sales
```

copy test data for hive queries into HDFS
```bash
hdfs dfs -put ~/BigData/data/adr_data.csv /user/hduser/hive_external/adr/
hdfs dfs -put ~/BigData/data/sales_data.csv /user/hduser/hive_external/sales/
# the following is outcommented, as it should already exist from previous tests
#hdfs dfs -put ~/BigData/data/Bibel.txt /input
```

## Next Steps
execute the hive CLI commands according to the instructions in `04l_hive_commands_part2.md`.
