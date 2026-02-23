# BigData04 - install MySQL as container

Start MySQL as a Docker/Podman container (MySQL works better as a metastore than the default "Derby"),
especially later with Sqoop and Flume

```bash
sudo -s
apt install docker.io
```

You may need to reboot here if a menu pops up, which asks you to do so
```bash
docker pull mysql
# Always set these variables when using the container
export DOCKER_CONTAINERNAME=swdMysql
export NETWORK=my-docker-network
docker network create --driver=bridge --subnet=10.0.4.0/24 --ip-range=10.0.4.0/24 --gateway=10.0.4.1 $NETWORK
```

Forward MySQL JDBC port 3306 to 13306
```bash
docker run --name ${DOCKER_CONTAINERNAME} --network $NETWORK -p 13306:3306 -e MYSQL_ROOT_PASSWORD=my-secret-pw -e MYSQL_DATABASE=swd -e MYSQL_USER=scott -e MYSQL_PASSWORD=tiger -d mysql:latest
```

Check whether everything went well...
```bash
docker logs swdMysql
```

For testing, connect to the docker container
```bash
docker exec -it -u mysql ${DOCKER_CONTAINERNAME} /bin/bash
```

With "-i --tty=false" you can pass a here-document to the Docker container, because it's non-interactive<br>
in this case you can see a Here-Document inside of another Here-Document (one with `EOF` and the other with `!`)
```bash
docker exec -i --tty=false -u mysql ${DOCKER_CONTAINERNAME} /bin/bash <<EOF
# The following block runs inside the container (use password "my-secret-pw")
mysql -u root -pmy-secret-pw <<!
   USE mysql;
   # The following is not necessary; schematool creates it anyway. Otherwise this would fail with a hint that the table exists.
   #SOURCE $MYSQL_SCHEMA_FILE;
   show tables;
!
EOF
```

## Next Steps
Continue with script `04h_hive_metastore_local_mysql.md`
