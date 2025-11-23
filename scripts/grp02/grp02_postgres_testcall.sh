#!/bin/bash
#################################################################
# Title:        grp02_postgres_testcall.sh
# Description:  test call against postgres DB in docker container     
# Parameters:  
#          $1:  username
#          $2:  hostname, where docker container runs
#################################################################

let NumParams=1   # number of mandatory parameters
let RetCode=0

Usage () {
   echo "USAGE: `basename $0` <username> [Postgres-Host]"
   echo "       Example: $0 swd00 datanode1"
   echo "   study in small letters and 2 digit current number"
}
#
if [ $# -lt $NumParams -o "$1" = "-?" -o "$1" = "--help" ]; then
   Usage;
   exit 1;
fi
export UserName=$1
export dbHost=${2:-datanode1}
export dbName=$UserName
export schemaName=$UserName
psql -h $dbHost -p 5432 -d $UserName -U $dbName <<!
 SET search_path TO $schemaName, public;
 CREATE OR REPLACE VIEW $schemaName.v_studentspostgres AS SELECT * FROM $schemaName.studentspostgres ORDER BY Last_Name DESC;
 SELECT * from $schemaName.v_studentspostgres;
!