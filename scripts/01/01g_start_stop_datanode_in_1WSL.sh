#################################################################
# Title:        01g_start_stop_datanode_in_1WSL.sh
# Description:  This is used for starting an additional datanode on an existing WSL, where already another datanode is running
#               das Script muss zum Starten/Stoppn pro zusätzlichem Datanode als user "hduser" aufgerufen werden              
# Parameters:  
#          $1:  node number
#          $2:  start|stop
#################################################################

let NumParams=2   # number of mandatory parameters
let RetCode=0

Usage () {
   echo "USAGE: `basename $0` <NodeNumber> start|stop"
   echo "       Example: $0 2 start # for 'datanode2'"
   echo "       mögliche Werte sind 2-9"
   echo "       das Script ist zum Starten und Stoppen eines zusätzlichen Datanodes gedacht,"
   echo "       nachdem in einer 'frischen' Session des users 'hduser' das start-df.sh ausgeführt wurde"
}
#
if [ $# -lt $NumParams -o "$1" = "-?" -o "$1" = "--help" ]; then
   Usage;
   exit 1;
fi
RetCode=0
# the real code starts here

echo "das Script sollte idealerweise nach start-dfs.sh ausgeführt werden"

# :
declare -i DN
DN=$1 # für weitere Datanodes diesen Wert verändern
if [ $DN -lt 2 -o $DN -gt 9 ]; then
   Usage;
   exit 1;
fi

export HADOOP_CONF_DIR=${HADOOP_HOME}/etc/datanode${DN}
# dort wird pid-File mit dem aktuell laufenden Prozess abgelegt - das muss unterschiedlich sein zw. den nodes,
# andernfalls würde das System sagen, dass der Prozess schon läuft
export HADOOP_PID_DIR=/usr/local/hadoop/hadoopdata/datanode${DN}/tmp
# und es sollte auch der Übersichtlichkeit halber eigene Logfiles geben
export HADOOP_LOG_DIR=${HADOOP_HOME}/logs/datanode${DN}
# zum Starten/Stoppen müssen dieselben Variablen gesetzt werden, damit die korrekte Instanz des datanodes beendet wird
hdfs --daemon $2 datanode
echo "running datanodes are:"
jps | grep DataNode
exit $?