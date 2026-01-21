#siehe Beispielkonfiguration unter https://www.syslog-ng.com/community/b/blog/posts/kafka-destination-improved-with-template-support-in-syslog-ng
sudo -s
apt install -y syslog-ng
# die folgende C++ Library ist nötig für die Integration von Kafka
apt install -y librdkafka-dev

cp -p /etc/syslog-ng/syslog-ng.conf /etc/syslog-ng/syslog-ng.conf.backup

# über Editor folgenden Abschnitt "s_src" erweitern um die 2 letzten Zeilen
vim /etc/syslog-ng/syslog-ng.conf

source s_src {
       system();
       internal();
       tcp(ip(0.0.0.0) port(514));
       udp(ip(0.0.0.0) port(514));
};

# und dann konfiguriere den Kafka-Connector
cat >/etc/syslog-ng/conf.d/kafka.conf <<!
destination d_kafka {
  kafka-c(config(metadata.broker.list("localhost:9092")
                   queue.buffering.max.ms("1000"))
        topic("syslogcollect")
        bootstrap-servers("localhost:9092")
        message("\$(format-json --scope rfc5424 --scope nv-pairs)"));
};

log {
  source(s_src);
  destination(d_kafka);
};
!

systemctl enable syslog-ng
systemctl start syslog-ng
# Bei Problemen, wenn das Service nicht started, wie folgt im Vordergrund aufrufen zur Ausgabe der Fehler
# syslog-ng -F

su - hduser
unset CLASSPATH
# Das Topic wurde bereits beim Call von syslog-Daemon über Datei /etc/syslog-ng/conf.d/kafka.conf angelegt, daher ist folgendes nachträglich nicht nötig
#$KAFKA_HOME/bin/kafka-topics.sh --create --topic syslogcollect --bootstrap-server localhost:9092  

# und dann versuchen wir, die Syslog-Events abzuholen und in Datei zu schreiben
$KAFKA_HOME/bin/kafka-console-consumer.sh --topic syslogcollect --from-beginning --bootstrap-server localhost:9092

# Dann einfach irgendein Syslog-Event auslösen, indem z.B. in einer anderen Session ein "su - hduser" ausgeführt wird:
# Erwartete Ausgabe ähnlich der folgenden
#{"SOURCE":"s_src","PROGRAM":"su","PRIORITY":"notice","PID":"34706","MESSAGE":"(to hduser) root on pts/2","HOST_FROM":"KSI5785","HOST":"KSI5785","FACILITY":"auth","DATE":"Dec  1 13:02:07"}
#{"SOURCE":"s_src","PROGRAM":"su","PRIORITY":"info","PID":"34706","MESSAGE":"pam_unix(su-l:session): session opened for user hduser(uid=1000) by (uid=0)","HOST_FROM":"KSI5785","HOST":"KSI5785","FACILITY":"authpriv","DATE":"Dec  1 13:02:07"}
#{"SOURCE":"s_src","PROGRAM":"systemd-logind","PRIORITY":"info","PID":"17200","MESSAGE":"New session c8 of user hduser.","HOST_FROM":"KSI5785","HOST":"KSI5785","FACILITY":"auth","DATE":"Dec  1 13:02:07"}
#{"SOURCE":"s_src","PROGRAM":"systemd","PRIORITY":"info","PID":"1","MESSAGE":"Started session-c8.scope - Session c8 of User hduser.","HOST_FROM":"KSI5785","HOST":"KSI5785","FACILITY":"daemon","DATE":"Dec  1 13:02:07"}
#{"SOURCE":"s_src","PROGRAM":"kernel","PRIORITY":"info","MESSAGE":"mini_init (175): drop_caches: 1","HOST_FROM":"KSI5785","HOST":"KSI5785","FACILITY":"kern","DATE":"Dec  1 13:02:13"}
