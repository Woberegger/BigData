# Oracle container download und erster Test, indem wir uns die User anzeigen lassen
# man kann podman oder docker verwenden, um die Container zu betreiben
# see https://container-registry.oracle.com/ords/f?p=113:4:106648115637034:::4:P4_REPOSITORY,AI_REPOSITORY,AI_REPOSITORY_NAME,P4_REPOSITORY_NAME,P4_EULA_ID,P4_BUSINESS_AREA_ID:1863,1863,Oracle%20Database%20Free,Oracle%20Database%20Free,1,0&cs=3vh3v7Bx-M1AhcZcni5BZw08qK4bc49cPe_X8TG5ZkK6Z8YJb6F_7s-kOEqsi9ahcAJrOaMTAC5QDMo1FbyMgWA

# Das Image ist ca. 14 GB gross, d.h. bitte auf ausreichend Speicher prüfen
docker pull container-registry.oracle.com/database/free:latest
export DOCKER_CONTAINERNAME=Oracle23Free
# damit der listener-Port 1521 von extern zugreifbar ist, muss dieser über "p xxx:xxx" freigegeben werden
docker run -d --name $DOCKER_CONTAINERNAME -p 1521:1521 container-registry.oracle.com/database/free:latest
docker exec $DOCKER_CONTAINERNAME ./setPassword.sh FhIms2024

# verbinde mit der Datenbank mit sqlplus innerhalb des Containers und zeige an, welche pdbs und welche user es gibt
# über --tty=false kann man eine Kommandosequenz als Here-Document übergeben
# das "-s" bei sqlplus gibt keinen SQL-Prompt und zeigt keinen SQL-Startscreen, ist daher bei nicht-interaktiven Kommandos anzuraten, sonst aber nicht
docker exec -i --tty=false $DOCKER_CONTAINERNAME sqlplus -s / as sysdba <<!
   show pdbs;
   SET lines 300 pages 0;
   SELECT UserName, user_id FROM all_users ORDER BY 2 ASC;
!
# zeige letzte Ausgaben des Oracle Alert-Logs
docker logs $DOCKER_CONTAINERNAME

# jetzt legen wir eine eigene Pluggable DB an als Kopie der Default-DB "FREEPDB1"
docker exec -i --tty=false $DOCKER_CONTAINERNAME sqlplus -s / as sysdba <<!
   SET lines 300 pages 0;
   -- Zeige die Struktur der Files an, damit wir das dann im File_Name_Convert analog dazu anlegen
   SELECT FILE_NAME FROM dba_data_files;
   CREATE Pluggable Database IMS FROM FREEPDB1 FILE_NAME_CONVERT=('/opt/oracle/oradata/FREE/FREEPDB1/','/opt/oracle/oradata/FREE/IMS/');
   -- Wechsle in den existierenden Container
   ALTER Pluggable Database IMS OPEN;
   ALTER session SET container=IMS;
   SELECT FILE_NAME FROM dba_data_files;
!
# wir müssen einen tns-Alias für die neue DB anlegen, damit wir mit user/pwd@PluggableDB uns anmelden können
docker exec -it $DOCKER_CONTAINERNAME /bin/bash
cat >>/opt/oracle/product/23c/dbhomeFree/network/admin/tnsnames.ora <<!
IMS =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCP)(HOST = 0.0.0.0)(PORT = 1521))
    (CONNECT_DATA =
      (SERVER = DEDICATED)
      (SERVICE_NAME = IMS)
    )
  )
! 
  
# damit wir später saubere Trennung haben, legen wir eigenen Tablespace für Daten und Indizes an
docker exec -i --tty=false $DOCKER_CONTAINERNAME sqlplus -s / as sysdba <<!
   -- WICHTIG: bei den meisten unserer Test-Anwendungen müssen wir in die jeweilige PDB wechseln, also das "ALTER SESSION" nicht vergessen!!!
   ALTER session SET container=IMS;
   CREATE TABLESPACE data DATAFILE '/opt/oracle/oradata/FREE/IMS/data.dbf' SIZE 16m AUTOEXTEND ON;
   CREATE TABLESPACE indexes DATAFILE '/opt/oracle/oradata/FREE/IMS/indexes.dbf' SIZE 8m AUTOEXTEND ON;
   SELECT FILE_NAME, auto_extent FROM dba_data_files;
   SELECT tablespace_name, INITIAL_EXTENT, NEXT_EXTENT, ENCRYPTED, EXTENT_MANAGEMENT FROM DBA_TableSpaces;
!

# und dann legen wir noch einen Applikationsuser in unserer PDB an, unter dem dann die Tabellen installiert werden
docker exec -i --tty=false $DOCKER_CONTAINERNAME sqlplus -s / as sysdba <<!
   ALTER session SET container=IMS;
   -- zuvor legen wir noch eine Rolle an, damit wir die dann dem User geben, bei einem weiteren User können wir dieselbe Rolle weiterverwenden
   CREATE Role Application;
   CREATE USER Ims IDENTIFIED BY FhIms2024 DEFAULT TABLESPACE DATA TEMPORARY TABLESPACE TEMP;
   GRANT CONNECT, RESOURCE, CREATE TABLE, CREATE PROCEDURE, CREATE VIEW, CREATE DATABASE LINK, CREATE SYNONYM, CREATE ANY DIRECTORY TO Application;
   GRANT CONNECT, RESOURCE, UNLIMITED TABLESPACE, Application TO Ims;
!

# und dann verbinden wir uns testweise mit dem neu angelegten User, der sollte zumindest ein paar Systemtabellen finden, eigene gibt es noch keine
docker exec -i --tty=false $DOCKER_CONTAINERNAME sqlplus -s ims/FhIms2024@IMS <<!
   SELECT Table_Name FROM All_Tables WHERE RowNum<=10;
   prompt hier wird erwarteterweise noch nichts gefunden
   SELECT * FROM cat;
!

### wenn man später die Pluggable DB droppen und neu anlegen will, muss man wie folgt vorgehen (Statements auskommentiert)
# docker exec -i --tty=false $DOCKER_CONTAINERNAME sqlplus -s / as sysdba <<!
#   alter pluggable database IMS close;
#   alter pluggable database IMS unplug into '/opt/oracle/oradata/ims.xml';
#   drop pluggable database IMS INCLUDING DATAFILES;
#!

###### später, wenn der Container runtergefahren wurde, wie folgt vorgehen zum Wiederhochfahren und Einloggen #########
docker start Oracle23Free
docker exec -it Oracle23Free sqlplus / as sysdba

### optional kann man instantclient installieren und damit sqlplus von ausserhalb verwenden, ist aber nicht nötig...
# cd /usr/local
# mkdir instantclient
# cd instantclient
# wget https://download.oracle.com/otn_software/linux/instantclient/23c/instantclient-basic-linux.x64-23.3.0.0.0.zip
# wget https://download.oracle.com/otn_software/linux/instantclient/23c/instantclient-sqlplus-linux.x64-23.3.0.0.0.zip
# unzip instantclient-sqlplus-linux.x64-23.3.0.0.0.zip
# export PATH=$PATH:/usr/local/instantclient/instantclient_23_3
# export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/instantclient/instantclient_23_3

sqlplus sys@localhost:1521/FREEPDB1 as sysdba