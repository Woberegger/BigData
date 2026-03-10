# BigDataGrp02 - install Oracle client

oracle basic client - consumes approx 132MB+6MB of size

this library `libaio1t64`is used by sqlplus (should anyway be present already, but create link)
```bash
sudo -s
apt install libaio1t64
ln -s /usr/lib/x86_64-linux-gnu/libaio.so.1t64 /usr/lib/libaio.so.1
```

download installer from oracle.com
```bash
cd /usr/local
wget https://download.oracle.com/otn_software/linux/instantclient/2326000/instantclient-basic-linux.x64-23.26.0.0.0.zip
wget https://download.oracle.com/otn_software/linux/instantclient/2326000/instantclient-sqlplus-linux.x64-23.26.0.0.0.zip
unzip instantclient-basic-linux.x64-23.26.0.0.0.zip
unzip instantclient-sqlplus-linux.x64-23.26.0.0.0.zip
```
to save space, eliminate the download file after unpacking
```bash
rm instantclient-basic-linux.x64-23.26.0.0.0.zip instantclient-sqlplus-linux.x64-23.26.0.0.0.zip
```

tell client, how to connect to Oracle
```bash
cd /usr/local/instantclient_23_26/network/admin
cat >tnsnames.ora <<!
ITM =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCP)(HOST = datanode1)(PORT = 1521))
    (CONNECT_DATA =
      (SERVER = DEDICATED)
      (SERVICE_NAME = ITM)
    )
  )
#
SWD =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCP)(HOST = datanode1)(PORT = 1521))
    (CONNECT_DATA =
      (SERVER = DEDICATED)
      (SERVICE_NAME = SWD)
    )
  )
!
```

optionally add this to PATH
```bash
echo "export PATH=\$PATH:/usr/local/instantclient_23_26" >>~/.bashrc
source ~/.bashrc
```

do test call against oracle DB
```bash
~hduser/BigData/grp02/grp02_oracle_testcall.sh <UserName>
```