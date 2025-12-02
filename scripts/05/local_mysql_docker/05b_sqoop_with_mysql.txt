# und damit man mit Sqoop auf Datenbanken zugreifen kann, braucht man z.B. einen entspr. JDBC Connector fuer mySQL
# VORSICHT: MySQL-Objekte sind per default case-sensitive, d.h. studentsMySQL != studentsmysql

su - hduser
# Wichtig der MySQL user braucht ein Verzeichnis im hdfs, anderenfalls gibt es exception "java.io.IOException: java.lang.ClassNotFoundException: students"
export MYSQL_USER=root
hdfs dfs -mkdir /user/${MYSQL_USER}
hdfs dfs -chmod 777 /user/${MYSQL_USER}

sudo -s
export DOCKER_CONTAINERNAME=swdMysql
export DATABASE_NAME=swd

# prüfen, ob der Container "swdMysql" läuft, andernfalls mit "docker start swdMysql" starten
docker ps

# testweise mal mit dem docker container verbinden, den wir in Übung 4 für Metadatastore erstellt haben
docker exec -it -u mysql ${DOCKER_CONTAINERNAME} /bin/bash

# und mit "-i --tty=false" kann man dem Docker-Container ein Here-Dokument übergeben, da nicht interaktiv
docker exec -i --tty=false -u mysql ${DOCKER_CONTAINERNAME} /bin/bash <<EOF
# im Container wird dann folgender Block ausgeführt (als Passwort "my-secret-pw")
mysql -u root -pmy-secret-pw <<!

CREATE DATABASE IF NOT EXISTS $DATABASE_NAME;
show databases;
use $DATABASE_NAME;

CREATE TABLE IF NOT EXISTS studentsMySQL (
    id INT PRIMARY KEY,
    first_name VARCHAR(80) NOT NULL,
    last_name VARCHAR(80) NOT NULL,
    entry_date DATE,
    course VARCHAR(80) NOT NULL
);
show tables;
!
EOF

# jetzt legen wir eine idente Tabelle in Hive an
# wenn Hive-Server (hive --service hiveserver2 &) verwendet wird, dann muss der Connectstring so gesetzt sein, andernfalls leer
su - hduser
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

# dann generiere ein csv-File über https://generatedata.com/ mit den benötigten Daten.
# Eine bereits generierte Version liegt im git Repo unter "data/students.csv"
# die generierten Daten ev. noch nachbearbeiten:
# a) Split auf Vorname+Nachname:
#    sed -i 's/ /,/g' students.csv
# b) ev. passendes Datumsformat mit padding (ist aber nicht nötig für unseren Testfall):

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

export DATABASE_NAME=swd
# Wichtig: port forward für mysql docker container auf 13306, native auf 3306
export MYSQL_PORT=13306
export MYSQL_USER=root
export MYSQL_PASSWD=my-secret-pw
export DOCKER_CONTAINERNAME=swdMysql

# liste auf, ob unsere Datenbank und unsere Tabelle "studentsMySQL" gefunden werden
sqoop-list-databases --connect jdbc:mysql://localhost:${MYSQL_PORT}  --username $MYSQL_USER --password ${MYSQL_PASSWD}
sqoop-list-tables --connect jdbc:mysql://localhost:${MYSQL_PORT}/${DATABASE_NAME} --username $MYSQL_USER --password ${MYSQL_PASSWD}

# Exportiere Daten von Sqoop nach MySQL (ist eher nicht der übliche Anwendungszweck), aber auch möglich
# -m 1 ... Anzahl an Mappern, hier derzeit immer 1
sqoop export --connect jdbc:mysql://localhost:${MYSQL_PORT}/${DATABASE_NAME}  \
   --table studentsMySQL --username $MYSQL_USER --password ${MYSQL_PASSWD}  \
   --export-dir /user/hive/warehouse/fh.db/students --num-mappers 1  \
   --driver com.mysql.cj.jdbc.Driver  --input-fields-terminated-by ',' \
   --input-lines-terminated-by '\n' --bindir /usr/local/hadoop/share/hadoop/common/lib

# prüfen in mySQL, ob die Daten vorhanden sind...
sudo docker exec -i --tty=false -u mysql ${DOCKER_CONTAINERNAME} /bin/bash <<EOF
mysql -u $MYSQL_USER -p${MYSQL_PASSWD} <<!
use $DATABASE_NAME;
SELECT * FROM studentsMySQL LIMIT 10;
!
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

sqoop import --connect jdbc:mysql://localhost:${MYSQL_PORT}/${DATABASE_NAME}  --username $MYSQL_USER --password ${MYSQL_PASSWD} \
   --table studentsMySQL  --driver com.mysql.cj.jdbc.Driver  --hive-import --hive-database fh \
   --hive-table studentsFromMySQL --hive-overwrite --num-mappers 1  \
   --bindir /usr/local/hadoop/share/hadoop/common/lib

# Sollte obiger Befehl nicht funktionieren, kann man versuchen, die MySQL Daten zumindest ins HDFS abzuholen und nicht direkt in Hive reinschreiben.
# Dann müsste man jedoch die Tabelle StudentsFromFile neu definieren als "external table" (diese erlauben keine Constraints)

# scheinbar muss man hier --query statt --table angeben, damit hier mit delimitern exportiert wird
sqoop import --connect jdbc:mysql://localhost:${MYSQL_PORT}/${DATABASE_NAME}  --username $MYSQL_USER --password ${MYSQL_PASSWD} \
   --query "SELECT * FROM studentsMySQL WHERE \$CONDITIONS" --split-by , --driver com.mysql.cj.jdbc.Driver \
   --target-dir /user/hduser/studentsFromFile --fields-terminated-by , --as-textfile \
   --num-mappers 1 --bindir /usr/local/hadoop/share/hadoop/common/lib
# prüfen, ob Daten korrekt vorhanden sind
hdfs dfs -cat /user/hduser/studentsFromFile/part* | head
    
# nur bei Derby Metastore: danach hiveserver wieder zu starten, damit beeline funktioniert
# hive --service hiveserver2 &

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
    
   SELECT * FROM studentsFromMySQL LIMIT 10;
!

# falls die Tabelle leer ist, dann hat sqoop import nicht funktioniert und sind die Ausgaben zu kontrollieren.
# für einen erneuten Versuch muss zuerst das Verzeichnis wieder gelöscht werden über
# hdfs dfs -rm -R /user/hduser/studentsMySQL (bzw. /user/hduser/studentsFromFile)