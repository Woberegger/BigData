# diese Anleitung zeigt, wie man rsyslogd aktiviert für Remote syslogging und dann über flume abgreift
# Anleitung siehe z.B.: https://betterstack.com/community/guides/logging/how-to-configure-centralised-rsyslog-server/
# (diese Anleitung beschreibt jedoch einen zentralen Server, wir wollen anstelle des zentralen Servers "flume" einsetzen)

# prüfe die aktuellen Einstellungen und ob rsyslogd installiert ist
# (Configfile sollte auf /etc/rsyslog.conf gestellt sein)
sudo -s
rsyslogd -v

# prüfen, ob Service läuft, gegebenenfalls über "enable" und "start" aktivieren
systemctl status rsyslog

# aktiviere folgende Zeilen in /etc/rsyslog.conf, damit per udp auf höheren Port anstelle von Standardport 514 rausgeloggt wird
# schreibe folgendes in Datei /etc/rsyslog.conf
# log to different port than usual 514 to be able to use non-privileged user to read from it
*.* @127.0.0.1:47111

# prüfen, dass z.B. folgende Zeile in /etc/rsyslog.d/50-default.conf aktiviert ist, somit sollten login Versuche getrackt werden
# wenn man andere Dinge, wie z.B. sonstige Records in /var/log/messages tracken will, dann aktiviere die entspr. Zeilen mit Filter
auth,authpriv.*                 /var/log/auth.log

# und starte danach syslog daemon neu
systemctl restart rsyslog

# in neuer Shell als hduser einloggen
su - hduser
cd /usr/local/flume
# flume config File erzeugen, in 1. Testansatz mal logging in Foreground 

cat >/usr/local/flume/conf/syslogudp.conf.logger_sink <<!
# Name the components on this agent
sysl.sources = syslog
sysl.sinks = logger
sysl.channels = memory

sysl.sources.syslog.type = syslogudp
# da wir als "hduser" starten, müssen wir einen Port > 1024 verwenden
sysl.sources.syslog.port = 47111
sysl.sources.syslog.host = localhost
sysl.sources.syslog.channels = memory

# Describe the sink
sysl.sinks.logger.type = logger


# Use a channel which buffers events in memory
sysl.channels.memory.type = memory
sysl.channels.memory.capacity = 1000
sysl.channels.memory.transactionCapacity = 100

# Bind the source and sink to the channel
sysl.sources.syslog.channels = memory
sysl.sinks.logger.channel = memory
!
./bin/flume-ng agent --conf conf/ -f conf/syslogudp.conf.logger_sink -n sysl -Dflume.root.logger=INFO,console

# testen, ob der Aufruf im syslog File erscheint und sollte dann auch bei Flume auftauchen
# erwartete Ausgabe ca. "INFO  [SinkRunner-PollingRunner-DefaultSinkProcessor] sink.LoggerSink: Event: { ... body: 72 6F 6F 74 3A 20 74 65 73 74 63 61 6C 6C 20 66 root: testcall f }"
logger 'testcall from client' && tail -n1 /var/log/syslog

# danach ist das dann umzubauen, dass anstelle von Logger auf hive oder hdfs geschrieben wird
# wegen der nötigen Parameter für Hive schaue https://community.cloudera.com/t5/Community-Articles/HiveSink-for-Flume/ta-p/245584 als Beispiel an
# Eine einfachere Möglichkeit wäre, das einfach ins hdfs zu schreiben und dann das generierte File ähnlich wie File Bibel.txt in Script
# 04_hive_commands.txt einzulesen und dann auszuwerten. Das folgende Beispiel schreibt Daten ins hdfs

hdfs dfs -mkdir -p hdfs://namenode:9000/user/hduser/syslog/

cat >/usr/local/flume/conf/syslogudp.conf.hdfs_sink <<!
# Name the components on this agent
sysl.sources = syslog
sysl.sinks = HDFS
sysl.channels = memory

#
sysl.sources.syslog.type = syslogudp
sysl.sources.syslog.port = 47111
sysl.sources.syslog.host = localhost
sysl.sources.syslog.channels = memory

# Describe the sink
sysl.sinks.HDFS.type = hdfs
# use prefix as output from command: hdfs dfs getconf -confKey fs.defaultFS
sysl.sinks.HDFS.hdfs.path = hdfs://namenode:9000/user/hduser/syslog/
# could also use time stamps in path names as in example below
#sysl.sinks.HDFS.hdfs.path = hdfs://namenode:9000/user/hduser/syslog/%y-%m-%d/%H
sysl.sinks.HDFS.hdfs.filePrefix = syslog
sysl.sinks.HDFS.hdfs.fileSuffix = .log
sysl.sinks.HDFS.hdfs.rollInterval = 0
sysl.sinks.HDFS.hdfs.rollCount = 10000
sysl.sinks.HDFS.hdfs.rollSize = 0
# write 1000 records into 1 file (needs to be <= sysl.channels.memory.transactionCapacity)
sysl.sinks.HDFS.hdfs.batchSize = 1000
sysl.sinks.HDFS.hdfs.fileType = DataStream

# Use a channel which buffers events in memory
sysl.channels.memory.type = memory
sysl.channels.memory.capacity = 10000
sysl.channels.memory.transactionCapacity = 1000

# Bind the source and sink to the channel
sysl.sources.syslog.channels = memory
sysl.sinks.HDFS.channel = memory
!
./bin/flume-ng agent --conf conf/ -f conf/syslogudp.conf.hdfs_sink -n sysl

# um testweise etwas mehr an Logdaten im File zu sehen und auch zu prüfen, ob neue Files erstellt werden:
for ((i=0;i<=200;i++)); do logger "log msg nr $i"; done

# Betrachten der Daten über
firefox --new-tab http://localhost:9870/explorer.html#/user/hduser/syslog
# zur Info: das zuletzt erstellte File bekommt extension ".tmp", erst wenn obiges flume-ng Kommando beendet wird, bekommt es den endgültigen Namen

# Wen man mit HDFS arbeiten will, dann einfach mal folgende Tabelle anlegen, das Laden muss halt hier interaktiv gemacht werden,
# während bei direkter Verwendung von Hive als Datensenke das Flume eventgetrieben weiterbefüllen würde.
# man kann hier den Pfad ohne einzelne Dateien angeben, dann können auch mehrere Dateien geladen werden.
CREATE TABLE logevents (logline STRING);
LOAD DATA INPATH '/user/hduser/syslog/' OVERWRITE INTO TABLE logevents;

# FLEISSAUFGABE: wenn das funktioniert, kann man das Configfile auf hive umstellen und eine Hive-Tabelle wie folgt anlegen:
# der Einfachheit halber loggen wir ganze Zeilen in die Tabelle rein und joinen dann mit String-Operations
beeline -u jdbc:hive2:// scott tiger
   set hive.execution.engine=mr;
   set hive.metastore.warehouse.dir;
   use default;
   --
   DROP TABLE logevents;
   CREATE TABLE IF NOT EXISTS logevents (
    logline STRING)
    COMMENT 'Syslog events as complete line'
    STORED AS ORC
    LOCATION '/user/hduser/hive_external/logevents';
!