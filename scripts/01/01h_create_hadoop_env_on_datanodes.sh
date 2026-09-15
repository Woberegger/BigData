#################################################################
# Title:        create_hadoop_env_on_datanodes.sh
# Description:  This script calls 01h_prepare_datanodes_in_openstack for all IPs
# Parameters:
#          $1:  study
#          $2:  PortOffset (100 for ITM and 0 for SWD)
#################################################################

let NumParams=2   # number of mandatory parameters
let RetCode=0

Usage () {
   echo "USAGE: `basename $0` <Study> <PortOffset>"
   echo "       Example: $0 ITM 100"
   echo "       for SWD use PortOffset 0, for ITM use 100"
}
#
if [ $# -lt $NumParams -o "$1" = "-?" -o "$1" = "--help" ]; then
   Usage;
   exit 1;
fi
RetCode=0
# the real code starts here
Study=$1
let PortOffset=$2
declare -i offset
expectedName=bigdata${Study}
grep $expectedName /etc/hosts >/tmp/bigdatahosts
cp ~/BigData/scripts/01/datanode.env ~/.
while read ip BDhost; do
   postfix=$(echo ${BDhost##${expectedName}})
   offset=$(printf %d ${postfix#0})
   let offset+=$PortOffset
   echo "calling ~/BigData/scripts/01/01h_prepare_datanodes_in_openstack.sh $offset $ip"
   ~/BigData/scripts/01/01h_prepare_datanodes_in_openstack.sh $offset $ip
done < /tmp/bigdatahosts
rm -f /tmp/bigdatahosts
exit $RetCode