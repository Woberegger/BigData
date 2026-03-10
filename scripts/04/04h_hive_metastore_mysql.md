# BigData04 - Hive Metastore with MySQL

The so-called `metastore` is the part, where the metadata of Hive is stored, e.g. the table definitions, the database definitions, the user permissions etc.<br>
By default, Hive uses an embedded Derby database for this, which is not suitable for production environments.
Therefore, we will use MySQL as the metastore database in this setup.

Preferably use mySQL on datanode1, so that you don't need to install it locally on your namenode VM.

**IMPORTANT:** Forward the port for the MySQL Docker/Podman container to 13306, otherwise there will be a conflict with a possibly natively installed MySQL. This is also configured in hive-site.xml.

set proper permissions, if not yet set before

```bash
su - hduser
hdfs dfs -chmod 777 /tmp /user/hive/warehouse
```

## Install MySQL Driver

Download driver from [MySQL Downloads](https://downloads.mysql.com) or **BETTER** use the version from GitHub:

```bash
cp ~/BigData/external_libs/mysql-connector-j-8.1.0.jar $HIVE_HOME/lib/
```

## Initialize Metadata Database

In this case, it's best to use the one on datanode1, so you don't need a local MySQL<br>
Tell the system, that it's type `mysql` (and not `derby`),<br>
all other settings like username, password and port are already set in `hive-site.xml`

```bash
cd $HIVE_HOME/bin && ./schematool -initSchema -dbType mysql -verbose
```

If something doesn't work and you want to start fresh, it's best to recursively delete the HDFS directories `/user/hive/warehouse` and `/user/hduser/hive_external` as well as `$HIVE_HOME/conf/metastore_db`.

## Start Hive Server

After all changes have been made, start the Hive-Server (dfs must be running):
This runs in the foreground, so for the following statements you need to open a new terminal session
(or you can add `&` at the end of the command to run it in the background, but then you won't see any logs, which makes troubleshooting more difficult):

```bash
start-dfs.sh
hive --service hiveserver2 --hiveconf hive.server2.thrift.port=10000
```

## start new terminal session

If everything went well, the following must show "LISTEN":

```bash
netstat -an | grep 10000
```

Otherwise, stop the hive-Server and do the following so that detailed logging shows where the problem is:

```bash
echo 'export HADOOP_CLIENT_OPTS="-Dhive.root.logger=console"' >$HIVE_HOME/conf/hive-env.sh
```

After starting the Hive-Server, the status should also be visible in the following web GUI [](http://<nameNodeIP>:10002).<br>
Later, after executing the first commands via `04l_hive_commands_part2.md` scripts, you will also see the command history:

start hive CLI (beeline) and connect to the server:

```bash
beeline --verbose
!connect jdbc:hive2://localhost:10000 scott tiger
```

**IMPORTANT**: If you get the error "Connection refused" or "user ... is not allowed to impersonate scott" with the beeline command, then the entry "hive.server2.enable.doAs" in hive-site.xml must be set to "false".


If the prompt above looks okay and does not report "closed", then the installation looks good and you can test creating objects. Exit the beeline shell with `<Ctrl>c`.

## Next Steps

Continue with script `04k_hive_commands_part1.md`
