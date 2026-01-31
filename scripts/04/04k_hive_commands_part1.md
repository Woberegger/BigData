# Start hdfs und yarn, sollten diese nicht schon laufen...
start-dfs.sh
start-yarn.sh
# ebenso hiveServer (der läuft im Hintergrund, Eingaben daher besser in anderer Session die Hive-Commandos eingeben
hive --service hiveserver2 --hiveconf hive.server2.thrift.port=10000 &

# Verzeichnisse für externe Hive-Daten in HDFS bereitstellen
hdfs dfs -mkdir -p /user/hduser/hive_external/adr
hdfs dfs -mkdir -p /user/hduser/hive_external/sales
# und Testdaten für Hive Abfragen ins hdfs kopieren
hdfs dfs -put ~/BigData/data/adr_data.csv /user/hduser/hive_external/adr/
hdfs dfs -put ~/BigData/data/sales_data.csv /user/hduser/hive_external/sales/
# das sollte ja bereits existieren von anderen Tests
#hdfs dfs -put ~/BigData/data/Bibel.txt /input

### in weiterer Session die Kommandos lt. 04l_hive_commands_part2.md eingeben ###
