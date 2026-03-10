# BigData05 - Kafka Syslog collector (optional)

this should stream Linux syslog events into Kafka consumer

see example configuration from [](https://www.syslog-ng.com/community/b/blog/posts/kafka-destination-improved-with-template-support-in-syslog-ng)

first install syslog-ng and the C++ library for Kafka integration
```bash
sudo -s
apt install -y syslog-ng
```

the following C++ Library is necessary for the Kafka integration into syslog-ng
```bash
apt install -y librdkafka-dev
```

to be on the save side, we better make a backup of the original syslog-ng configuration file, because we will adapt it
```bash
cp -p /etc/syslog-ng/syslog-ng.conf /etc/syslog-ng/syslog-ng.conf.backup
```

in your preferred editor (e.g. `nano` or `vim`) open the file `/etc/syslog-ng/syslog-ng.conf` and add the following lines to the source section
```vim
source s_src {
       system();
       internal();
       tcp(ip(0.0.0.0) port(514));
       udp(ip(0.0.0.0) port(514));
};
```

and then configure the Kafka connector
```bash
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
```

and then we enable and start the syslog-ng service
```bash
systemctl enable syslog-ng
systemctl start syslog-ng
```

> if you encounter a problem, that the service is not starting, you can try following command:
```bash
syslog-ng -F
```

the next actions are done as `hduser` to test the Kafka topic and consumer
```bash
su - hduser
unset CLASSPATH
```
The topic was already created when the syslog-daemon was called via the file /etc/syslog-ng/conf.d/kafka.conf, so the following is not necessary<br>
~~$KAFKA_HOME/bin/kafka-topics.sh --create --topic syslogcollect --bootstrap-server localhost:9092~~

And then we try to retrieve the Syslog events and write them to a file
```bash
$KAFKA_HOME/bin/kafka-console-consumer.sh --topic syslogcollect --from-beginning --bootstrap-server localhost:9092
```

Then simply trigger any Syslog event by, for example, executing "su - hduser" in another session:

Expected output similar to the following:

> {"SOURCE":"s_src","PROGRAM":"su","PRIORITY":"notice","PID":"34706","MESSAGE":"(to hduser) root on pts/2","HOST_FROM":"KSI5785","HOST":"KSI5785","FACILITY":"auth","DATE":"Dec  1 13:02:07"}<br>
> {"SOURCE":"s_src","PROGRAM":"su","PRIORITY":"info","PID":"34706","MESSAGE":"pam_unix(su-l:session): session opened for user hduser(uid=1000) by (uid=0)","HOST_FROM":"KSI5785","HOST":"KSI5785","FACILITY":"authpriv","DATE":"Dec  1 13:02:07"}<br>
> {"SOURCE":"s_src","PROGRAM":"systemd-logind","PRIORITY":"info","PID":"17200","MESSAGE":"New session c8 of user hduser.","HOST_FROM":"KSI5785","HOST":"KSI5785","FACILITY":"auth","DATE":"Dec  1 13:02:07"}<br>
> {"SOURCE":"s_src","PROGRAM":"systemd","PRIORITY":"info","PID":"1","MESSAGE":"Started session-c8.scope - Session c8 of User hduser.","HOST_FROM":"KSI5785","HOST":"KSI5785","FACILITY":"daemon","DATE":"Dec  1 13:02:07"}<br>
> {"SOURCE":"s_src","PROGRAM":"kernel","PRIORITY":"info","MESSAGE":"mini_init (175): drop_caches: 1","HOST_FROM":"KSI5785","HOST":"KSI5785","FACILITY":"kern","DATE":"Dec  1 13:02:13"}<br>
