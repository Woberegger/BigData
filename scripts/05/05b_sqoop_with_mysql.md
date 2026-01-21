# und damit man mit Sqoop auf Datenbanken zugreifen kann, braucht man z.B. einen entspr. JDBC Connector fuer mySQL
# VORSICHT: MySQL-Objekte sind per default case-sensitive, d.h. studentsMySQL != studentsmysql
# mysql-client - approx 86MB of size
sudo apt install default-mysql-client

su - hduser

# testweise mit mysql Docker container auf datanode1 verbinden
# Wichtig: port forward für mysql docker container auf 13306, native üblicherweise auf 3306
export MYSQL_PORT=13306
export MYSQL_USER=$(echo ${HOSTNAME//bigdata})
export MYSQL_PASSWD=$MYSQL_USER
export DATABASE_NAME=$MYSQL_USER
export MYSQL_HOST=datanode1
~/BigData/scripts/grp02/grp02_mysql_testcall.sh $MYSQL_USER $MYSQL_HOST

# Wichtig der MySQL user braucht ein Verzeichnis im hdfs, anderenfalls gibt es exception "java.io.IOException: java.lang.ClassNotFoundException: students"
hdfs dfs -mkdir /user/${MYSQL_USER}
hdfs dfs -chmod 777 /user/${MYSQL_USER}

mysql --ssl=FALSE -u $MYSQL_USER -D $DATABASE_NAME -h $MYSQL_HOST -P 13306 --password=$MYSQL_PASSWD <<EOF

CREATE DATABASE IF NOT EXISTS $DATABASE_NAME;
use $DATABASE_NAME;
# entry_date as DATE does not work with sqoop export, so use VARCHAR for it.
CREATE TABLE IF NOT EXISTS studentsMySQL (
    id INT PRIMARY KEY,
    first_name VARCHAR(80) NOT NULL,
    last_name VARCHAR(80) NOT NULL,
    entry_date VARCHAR(20) NOT NULL,
    course VARCHAR(80) NOT NULL
);
show tables;
EOF

# in eigener shell hiveserver starten, sollte er noch nicht laufen
hive --service hiveserver2 --hiveconf hive.server2.thrift.port=10000
# jetzt legen wir eine idente Tabelle in Hive an

export HIVE_CONNECT_STRING=localhost:10000
beeline -u jdbc:hive2://${HIVE_CONNECT_STRING} scott tiger <<!
   set hive.execution.engine=mr;
   set hive.metastore.warehouse.dir;
   create database if not exists fh;
   show databases;
   use fh;
   show tables;
   -- diese Tabelle kopieren wir von Hive nach mySQL
   DROP table students;
   CREATE TABLE IF NOT EXISTS students( id INT , first_name STRING, last_name STRING, entry_date DATE, course STRING)
      COMMENT 'Students to sync with mySQL'
      ROW FORMAT DELIMITED FIELDS TERMINATED BY ',';
   describe students;
   -- und in diese Tabelle wieder retour von MySQL
   DROP table studentsFromMySQL;
   CREATE TABLE IF NOT EXISTS studentsFromMySQL ( id INT , first_name STRING, last_name STRING, entry_date DATE, course STRING)
   COMMENT 'Students to sync with mySQL';
!

# wir können die Datei ins hdfs reinladen oder benutzen hier mal das "LOCAL INPATH" zum Laden von lokaler Datei
# hdfs dfs -put BigData/data/students.csv /tmp/
beeline -u jdbc:hive2://${HIVE_CONNECT_STRING} scott tiger <<!
   use fh;
   LOAD DATA LOCAL INPATH '/home/hduser/BigData/data/students.csv' OVERWRITE INTO TABLE students;
   select * from students limit 10;
!

# scheinbar muss man die mapreduce Jar Files rüberkopieren, andernfalls gibt es "ClassNotFound" exception
cp -p /usr/local/hadoop/share/hadoop/mapreduce/*.jar $SQOOP_HOME/lib/
# weiters generiert Sqoop eine Klasse "students.jar" für den Import, die im ClassPath gefunden werden muss
# Daher ist der Parameter --bindir auf z.B. /usr/local/hadoop/share/hadoop/common/lib zu setzen

# liste auf, ob unsere Datenbank und unsere Tabelle "studentsMySQL" gefunden werden
sqoop-list-databases --connect jdbc:mysql://${MYSQL_HOST}:${MYSQL_PORT}  --username $MYSQL_USER --password ${MYSQL_PASSWD}
sqoop-list-tables --connect jdbc:mysql://${MYSQL_HOST}:${MYSQL_PORT}/${DATABASE_NAME} --username $MYSQL_USER --password ${MYSQL_PASSWD}

# Exportiere Daten von Sqoop nach MySQL (ist eher nicht der übliche Anwendungszweck), aber auch möglich
# -m 1 ... Anzahl an Mappern, hier derzeit immer 1
sqoop export --connect jdbc:mysql://${MYSQL_HOST}:${MYSQL_PORT}/${DATABASE_NAME}  \
   --table studentsMySQL --username $MYSQL_USER --password ${MYSQL_PASSWD}  \
   --export-dir /user/hive/warehouse/fh.db/students --num-mappers 1  \
   --driver com.mysql.cj.jdbc.Driver  --input-fields-terminated-by ',' \
   --input-lines-terminated-by '\n' --bindir /usr/local/hadoop/share/hadoop/common/lib

# prüfen in mySQL, ob die Daten vorhanden sind...
mysql --ssl=FALSE -u $MYSQL_USER -D $DATABASE_NAME -h $MYSQL_HOST -P 13306 --password=$MYSQL_PASSWD <<EOF
use $DATABASE_NAME;
SELECT * FROM studentsMySQL LIMIT 10;
EOF

# die andere Richtung am besten testen, indem eine 2. Tabelle in Hive angelegt wird
# Verzeichnis löschen, falls von vorigem Versuch noch was existiert
hdfs dfs -rm -R /user/hduser/studentsMySQL 2>/dev/null
# möglicherweise gibt es Fehler, der jedoch üblicherweise eine Folgeerscheinung ist, weil die Java VM den Zugriff auf die Datei
# /usr/local/hive/lib/derby-10.14.2.0.jar nicht erlaubt:
#java.lang.NoClassDefFoundError: Could not initialize class org.apache.derby.jdbc.EmbeddedDriver
# Daher Inhalt von File ../grp02/grp02_java_policy_to_add.txt am Beginn von Datei $JAVA_HOME/lib/security/default.policy
# also z.B. /usr/lib/jvm/temurin-11-jdk-amd64/lib/security/default.policy einzutragen:
# bzw. folgende Zeilen in den generischen grant { ... } Abschnitt am Ende der Datei:
#    permission javax.management.MBeanTrustPermission "register";
#    permission org.apache.derby.security.SystemPermission "engine", "usederbyinternals";

# ACHTUNG: Bei Verwendung von derby als Metadatenbank für Hive (=default) ist zu beachten, dass Derby keine
#          konkurrierenden Zugriffe erlaubt, d.h. vor dem Sqoop-Import ist hive-server zu beenden
# !!! Wenn wir mySQL als Metadatenbank verwenden, dann ist dies nicht nötig !!!
# kill $(ps aux | grep hiveserver2 | grep -v grep | awk '{ print $2}')

# Wichtig ist auch, dass "-m 1" bzw. "--num-mappers 1" gesetzt wird, damit nur 1 Connection zu MySql geöffnet wird

sqoop import --connect jdbc:mysql://${MYSQL_HOST}:${MYSQL_PORT}/${DATABASE_NAME}  --username $MYSQL_USER --password ${MYSQL_PASSWD} \
   --table studentsMySQL  --driver com.mysql.cj.jdbc.Driver  --hive-import --hive-database fh \
   --hive-table studentsFromMySQL --hive-overwrite -m 1  \
   --bindir /usr/local/hadoop/share/hadoop/common/lib

# Sollte obiger Befehl nicht funktionieren, kann man versuchen, die MySQL Daten zumindest ins HDFS abzuholen und nicht direkt in Hive reinschreiben.
# Dann müsste man jedoch die Tabelle StudentsFromFile neu definieren als "external table" (diese erlauben keine Constraints)

# scheinbar muss man hier --query statt --table angeben, damit hier mit delimitern exportiert wird
sqoop import --connect jdbc:mysql://${MYSQL_HOST}:${MYSQL_PORT}/${DATABASE_NAME}  --username $MYSQL_USER --password ${MYSQL_PASSWD} \
   --query "SELECT * FROM studentsMySQL WHERE \$CONDITIONS" --split-by , --driver com.mysql.cj.jdbc.Driver \
   --target-dir /user/hduser/studentsFromFile --fields-terminated-by , --as-textfile \
   -m 1 --bindir /usr/local/hadoop/share/hadoop/common/lib
# prüfen, ob Daten korrekt vorhanden sind
hdfs dfs -cat /user/hduser/studentsFromFile/part* | head

# verifiziere die Inhalte
export HIVE_CONNECT_STRING=localhost:10000
beeline -u jdbc:hive2://${HIVE_CONNECT_STRING} scott tiger <<!
   set hive.execution.engine=mr;
   set hive.metastore.warehouse.dir;
   use fh;
   
   CREATE EXTERNAL TABLE IF NOT EXISTS studentsFromFile (
    id INT,
    first_name string,
    last_name string,
    entry_date DATE,
    course string)
    COMMENT 'StudentsAsHDFSFile'
    ROW FORMAT DELIMITED
    FIELDS TERMINATED BY ','
    STORED AS TEXTFILE
    LOCATION '/user/hduser/studentsFromFile';
   -- what we have loaded from Sqoop into HDFS 
   SELECT * FROM studentsFromFile LIMIT 10;
   -- what we have loaded from Sqoop directly into hive 
   SELECT * FROM studentsFromMySQL LIMIT 10;
!

# falls beide Tabellen leer sind, dann hat sqoop import nicht funktioniert und sind die Ausgaben zu kontrollieren.
# für einen erneuten Versuch muss zuerst das Verzeichnis wieder gelöscht werden über
# hdfs dfs -rm -R /user/hduser/studentsMySQL (bzw. /user/hduser/studentsFromFile)