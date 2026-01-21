# Wichtig: port forward für mysql docker container auf 13306, da andernfalls Konflikt mit eventuell native installiertem MySQL
#          das ist auch so in hive-site.xml konfiguriert
su - hduser
hdfs dfs -chmod 777 /tmp /user/hive/warehouse
  
# download driver from https://downloads.mysql.com bzw. besser gleich die Version aus github verwenden
cp ~/BigData/external_libs/mysql-connector-j-8.1.0.jar $HIVE_HOME/lib/

# Initialisieren der Metadaten-Datenbank: in dem Fall am besten die auf datanode1 verwenden, dann braucht man kein lokales MySQL
cd $HIVE_HOME/bin && ./schematool -initSchema -dbType mysql -verbose
# wenn mal gar nichts mehr funktioniert und man neu beginnen will, am besten HDFS Verzeichnisse /user/hive/warehouse und /user/hduser/hive_external
# sowie $HIVE_HOME/conf/metastore_db rekursiv löschen

# nachdem alle Changes gemacht wurden, Hive-Server starten (dfs und yarn müssen laufen)
hive --service hiveserver2 --hiveconf hive.server2.thrift.port=10000 &
# wenn alles gutgegangen ist, muss folgendes ein "listen" anzeigen
netstat -an | grep 10000
#Andernfalls hive-Server beenden und folgendes machen, damit detailliert geloggt wird, wo das Problem liegt
echo 'export HADOOP_CLIENT_OPTS="-Dhive.root.logger=console"' >$HIVE_HOME/conf/hive-env.sh

# nach dem Starten des Hive-Servers, sollte der Status auch in folgender Web-GUI sichtbar sein
# später nach dem Ausführen der ersten Kommandos über 04l_hive_commands_part2.txt scripts sieht man auch die Kommandohistorie
"%ProgramFiles%\Google\Chrome\Application\chrome.exe" --new-tab http://<nameNodeIP>:10002

# !!! die folgenden Dinge besser in neuer Session eingeben, da sonst eventuelle Ausgaben von Hiveserver im Hintergrund verwirren !!!

beeline --verbose
!connect jdbc:hive2://localhost:10000 scott tiger
# WICHTIG: Falls es Fehler "Connection refused" "user ... is not allowed to impersonate scott" bei beeline Kommando gibt,
# dann muss der Eintrag "hive.server2.enable.doAs" in hive-site.xml auf "false" gesetzt sein.

# Wenn obiges Prompt o.k. aussieht und nicht "closed" meldet, dann schaut Installation gut aus und man kann mal testweise Objekte anlegen 
# mit "<Ctrl>c" verlässt man die beeline shell

# weiter mit Script 04k_hive_commands_part1.txt