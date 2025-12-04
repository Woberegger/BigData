#!/usr/bin/bash
# This is used for starting/stopping multiple datanodes on the same machine.
# put it into $HADOOP_HOME/sbin directory and give it 744 permissions
# run it as user "hduser"

let NumParams=2   # number of mandatory parameters
let RetCode=0

Usage () {
   echo "USAGE: `basename $0` <start|stop> <NodeN> [NodeX] ..."
   echo "       Example: $0 start 2 3 ... to start datanodes 2 and 3, i.e. 'datanode2' and 'datanode3'"
}
#
run_datanode () {
   CMD=$1
   DN=$2
   export HADOOP_LOG_DIR=$DN_DIR_PREFIX$DN/logs
   export HADOOP_PID_DIR=$HADOOP_LOG_DIR
   export HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop
   export HADOOP_DATANODE_OPTS="\
   -Dhadoop.tmp.dir=$DN_DIR_PREFIX$DN\
   -Ddfs.datanode.address=0.0.0.0:5001$DN \
   -Ddfs.datanode.http.address=0.0.0.0:5008$DN \
   -Ddfs.datanode.ipc.address=0.0.0.0:5002$DN"
   hdfs --daemon $CMD datanode --workers --config ${HADOOP_CONF_DIR}
   #### TODO: the following does not work yet - pls investigate ####
   
   #$HADOOP_HOME/sbin/hadoop-daemon.sh --config ${HADOOP_CONF_DIR} $CMD  datanode $HADOOP_DATANODE_OPTS
   #hdfs datanode "${HADOOP_HDFS_HOME}/bin/hdfs" \
   # --config "${HADOOP_CONF_DIR}"\
   # --workers \
   # --daemon $1 \
   # datanode -regular
   #$HADOOP_HOME/sbin/hadoop-daemon.sh --script $HADOOP_HOME/bin/hdfs $1 datanode $DN_CONF_OPTS
}

if [ $# -lt $NumParams -o "$1" = "-?" -o "$1" = "--help" ]; then
   Usage;
   exit 1;
else
   RetCode=0
   # the real code starts here
   DN_DIR_PREFIX="$HADOOP_HOME/hadoopdata/datanode"

   cmd=$1
   shift;

   for i in $*; do
      run_datanode $cmd $i
   done

fi
exit $RetCode
