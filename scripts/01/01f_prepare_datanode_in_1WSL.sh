#################################################################
# Title:        01f_prepare_datanode_in_1WSL.sh
# Description:  This is used for starting an additional datanode on an existing WSL, where already another datanode is running
#               das Script muss einmalig pro zusätzlichem Datanode als user "hduser" aufgerufen werden              
# Parameters:  
#          $1:  node number
#################################################################

let NumParams=1   # number of mandatory parameters
let RetCode=0

Usage () {
   echo "USAGE: `basename $0` <NodeNumber>"
   echo "       Example: $0 2 # for 'datanode2'"
   echo "       mögliche Werte sind 1-9"
   echo "       das Script muss einmalig pro zusätzlichem Datanode als user 'hduser' aufgerufen werden"
}
#
if [ $# -lt $NumParams -o "$1" = "-?" -o "$1" = "--help" ]; then
   Usage;
   exit 1;
fi
RetCode=0
# the real code starts here

echo "das folgende muss einmalig als root user gemacht werden:"
echo '"127.0.0.1 datanode2 datanode3 datanode4" >>/etc/hosts'

# :
declare -i DN
DN=$1 # für weitere Datanodes diesen Wert verändern
if [ $DN -lt 1 -o $DN -gt 9 ]; then
   Usage;
   exit 1;
fi

cd $HADOOP_HOME/etc
cp -pR hadoop datanode${DN}
export HADOOP_CONF_DIR=${HADOOP_HOME}/etc/datanode${DN}

cat >${HADOOP_CONF_DIR}/hdfs-site.xml <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
        <property>
                <name>dfs.replication</name>
                <value>2</value>
        </property>
        <property>
                <name>dfs.permissions</name>
                <value>false</value>
        </property>
        <property>
                <name>dfs.namenode.name.dir</name>
                <value>file:/usr/local/hadoop/hadoopdata/hdfs/namenode</value>
        </property>
        <property>
                <name>dfs.datanode.data.dir</name>
                <value>file:/usr/local/hadoop/hadoopdata/hdfs/datanode${DN}</value>
        </property>
        <property>
                <name>dfs.block.size</name>
                <value>4194304</value>
        </property>
        <property>
          <name>dfs.namenode.accesstime.precision</name>
          <value>3600000</value>
        </property>
        <property>
          <name>dfs.nfs3.dump.dir</name>
          <value>/tmp/.hdfs-nfs</value>
        </property>
        <property>
          <name>dfs.nfs.exports.allowed.hosts</name>
          <value>* rw</value>
        </property>
        <property>
          <name>nfs.metrics.percentiles.intervals</name>
          <value>100</value>
        </property>
        <property>
          <name>nfs.port.monitoring.disabled</name>
          <value>false</value>
        </property>
    <!-- DataNode X Konfiguration (eigene Ports) -->
    <property>
        <name>dfs.datanode.hostname</name>
        <value>datanode${DN}</value>
    </property>

    <property>
        <name>dfs.datanode.address</name>
        <value>0.0.0.0:5001${DN}</value>
    </property>

    <property>
        <name>dfs.datanode.http.address</name>
        <value>0.0.0.0:5008${DN}</value>
    </property>

    <property>
        <name>dfs.datanode.ipc.address</name>
        <value>0.0.0.0:5002${DN}</value>
    </property>

</configuration>
EOF

sed -i "s#/usr/local/hadoop/hadoopdata/hdfs/tmp#/usr/local/hadoop/hadoopdata/datanode${DN}/tmp#" ${HADOOP_CONF_DIR}/core-site.xml

echo "in order to start/stop that prepared datanode call '01g_start_stop_datanode_in_1WSL.sh' as 'hduser'"
exit $RetCode