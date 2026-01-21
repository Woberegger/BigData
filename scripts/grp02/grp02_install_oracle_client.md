# oracle basic client - approx 132MB+6MB of size
sudo -s
# this library is used by sqlplus (should anyway be present already, but create link)
apt install libaio1t64
ln -s /usr/lib/x86_64-linux-gnu/libaio.so.1t64 /usr/lib/libaio.so.1
#
cd /usr/local
wget https://download.oracle.com/otn_software/linux/instantclient/2326000/instantclient-basic-linux.x64-23.26.0.0.0.zip
wget https://download.oracle.com/otn_software/linux/instantclient/2326000/instantclient-sqlplus-linux.x64-23.26.0.0.0.zip
unzip instantclient-basic-linux.x64-23.26.0.0.0.zip
unzip instantclient-sqlplus-linux.x64-23.26.0.0.0.zip
# to save space, eliminate the download file
rm instantclient-basic-linux.x64-23.26.0.0.0.zip instantclient-sqlplus-linux.x64-23.26.0.0.0.zip
# tell client, how to connect
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
# Test call
optionally add this to PATH
export PATH=$PATH:/usr/local/instantclient_23_26
# continue with grp02_oracle_testcall.sh to test the oracle call