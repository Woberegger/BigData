#!/bin/bash
#################################################################
# Title:        grp02_oracle_testcall.sh
# Description:  test call against oracle DB in docker container     
# Parameters:  
#          $1:  username
#          $2:  hostname, where docker container runs
#          $3:  ServiceName
#################################################################

let NumParams=1   # number of mandatory parameters
let RetCode=0

Usage () {
   echo "USAGE: `basename $0` <username> [Oracle-Host] [ServiceName]"
   echo "       Example: $0 swd00 datanode1 SWD"
   echo "   study in small letters and 2 digit current number"
   echo "   default service name is study in capital letters"
}
#
if [ $# -lt $NumParams -o "$1" = "-?" -o "$1" = "--help" ]; then
   Usage;
   exit 1;
fi
UserName=$1
Passwd=$UserName
dbHost=${2:-datanode1}
dbName=${3:-${UserName:0:3}}

echo "try to connect to ORACLE service $dbName as user $UserName"

/usr/local/instantclient_23_26/sqlplus -l $UserName/$Passwd@$dbName<<!
   create table if not exists test (a varchar2(10), b number(3));
   drop table test;
!
