#!/bin/bash
#################################################################
# Title:        grp02_mysql_testcall.sh
# Description:  test call against mysql DB in docker container     
# Parameters:  
#          $1:  username
#          $2:  hostname, where docker container runs
#################################################################

let NumParams=1   # number of mandatory parameters
let RetCode=0

Usage () {
   echo "USAGE: `basename $0` <username> [mySQL-Host]"
   echo "       Example: $0 swd00 datanode1"
   echo "   study in small letters and 2 digit current number"
}
#
if [ $# -lt $NumParams -o "$1" = "-?" -o "$1" = "--help" ]; then
   Usage;
   exit 1;
fi
UserName=$1
Passwd=$UserName
dbHost=${2:-datanode1}
dbName=$UserName

echo "First connect to private test schema $UserName in database $dbName, which should be empty"
mysql --ssl=FALSE -u $UserName -D $dbName -h $dbHost -P 13306 --password=$Passwd <<!
   show tables;
!

#UserName=${UserName}hive
#Passwd=$UserName
#dbName=$UserName
#
#echo "Then connect to Hive Metastore DB with user $UserName in database $dbName, which should find 83 tables, after 'schematool' for hive was executed"
#mysql --ssl=FALSE -u $UserName -D $dbName -h $dbHost -P 13306 --password=$Passwd <<!
#   show tables;
#!
