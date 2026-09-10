# BigData01 - initially start and test hadoop

all actions in this file are executed as user "hduser" !!!

## initially only once (!) format the HDFS file system
should only be called again, when deleting all data and starting from scratch(!!!)

```bash
su - hduser
```

```bash
hdfs namenode -format
```

## start hadoop (and optionally yarn) for the first time
start hadoop and yarn (as hduser)
```bash
start-dfs.sh
start-yarn.sh
```

optionally this works also with individual daemons, especially to debug it, if one process should not start up properly
```bash
#hdfs --daemon   start namenode
#hdfs --daemon   start datanode
#hdfs --daemon   start secondarynamenode
#yarn --daemon   start resourcemanager
#yarn --daemon   start nodemanager
#mapred --daemon start historyserver
```

## check, if all is working
Check, if all expected processes are running
```bash
jps | sort -k2
```

expected output are the following 6 java processes (of course with different PID)
>7444 DataNode<br>
>8129 Jps<br>
>7290 NameNode<br>
>7958 NodeManager<br>
>6024 ResourceManager<br>
>7642 SecondaryNameNode<br>

if there exists a problem like *No such rcmd module "ssh"* it may be necessary to additionally install package "pdsh-rcmd-ssh"!

### show status in Web GUI
locally on your laptop start your preferred browser (replace "\<ip_of_VM\>" with your VM's particular IP address)<br>
> hadoop: http://\<ip_of_VM\>:9870<br>
> yarn: http://\<ip_of_VM\>:8088<br>

in case of problems best look into the logfiles located under /usr/local/hadoop/logs

finally stop yarn and hadoop (as user "hduser")
```bash
stop-yarn.sh 
stop-dfs.sh
```

again stopping (like starting) can also be done individually with each individual process daemon
```bash
#hdfs --daemon stop namenode
#hdfs --daemon stop datanode
#hdfs --daemon stop secondarynamenode
#yarn --daemon stop nodemanager
#yarn --daemon stop resourcemanager
#mapred --daemon stop historyserver
```
