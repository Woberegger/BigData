#################################################################
# Title:        01f_prepare_datanodes_in_openstack.sh
# Description:  This is used for starting a student-specific datanode on central datanodes
#               it has to be executed once per student and datanode (as user "hduser")            
# Parameters:  
#          $1:  port number postfix
#          $2:  IP address of student-specific openstack namenode
#################################################################

let NumParams=2   # number of mandatory parameters
let RetCode=0

Usage () {
   echo "USAGE: `basename $0` <PortNumber> <NameNode-IP-Address>"
   echo "       Example: $0 3 10.77.16.124"
   echo "       the value has to be the according numerical postfix of the datanode's name, e.g. for bigdataSWD03 use value '3', ITM students use 100+"
   echo "       This script has to be executed once on each additional datanode (beside the one, which runs on namenode) as user 'hduser'"
   echo "       if you have logged in from that client, you can try: `basename $0` 3 \$(echo \$SSH_CLIENT | cut -d' ' -f1)"
}
#
if [ $# -lt $NumParams -o "$1" = "-?" -o "$1" = "--help" ]; then
   Usage;
   exit 1;
fi
RetCode=0
# the real code starts here
PortPostfix=$(printf %03d $1)
NameNodeIP=$2
if [ ! -n "$SSH_CLIENT" ]; then export SSH_CLIENT=$NameNodeIP; fi
echo "creating environment for PortPostfix $PortPostfix and namenode $NameNodeIP"

cd $HADOOP_HOME/etc
cp -pRT hadoop datanode${NameNodeIP}
export HADOOP_CONF_DIR=${HADOOP_HOME}/etc/datanode${NameNodeIP}

cat >${HADOOP_CONF_DIR}/core-site.xml <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
  <property>
    <name>fs.defaultFS</name>
    <value>hdfs://${NameNodeIP}:9000</value>
  </property>
  <property>
    <name>hadoop.tmp.dir</name>
    <value>/usr/local/hadoop/hadoopdata/datanode${NameNodeIP}/tmp</value>
  </property>
  <property>
    <name>fs.trash.interval</name>
    <value>1440</value>
  </property>
  <property>
    <name>fs.trash.checkpoint.interval</name>
    <value>60</value>
  </property>
</configuration>
EOF

# replace the shuffle default port 13562
cat >${HADOOP_CONF_DIR}/mapred-site.xml <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
   <property>
      <name>mapreduce.shuffle.port</name>
      <value>59${PortPostfix}</value>
   </property>
   <property>
      <name>mapreduce.job.tracker</name>
      <value>${NameNodeIP}:9001</value>
   </property>
   <!-- IMPORTANT: set this parameter to use Yarn and not local mode for computation -->
   <property>
      <name>mapreduce.framework.name</name>
      <value>yarn</value>
   </property>
</configuration>
EOF

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
      <value>file:/usr/local/hadoop/hadoopdata/hdfs/datanode${NameNodeIP}</value>
   </property>
   <property>
      <name>dfs.namenode.heartbeat.recheck-interval</name>
      <value>15000</value>
      <description>Determines datanode heartbeat interval in milliseconds</description>
   </property>
   <property>
      <name>dfs.block.size</name>
      <value>2097152</value>
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
      <name>dfs.datanode.address</name>
      <value>0.0.0.0:51${PortPostfix}</value>
   </property>
   <property>
      <name>dfs.datanode.http.address</name>
      <value>0.0.0.0:58${PortPostfix}</value>
   </property>
   <property>
      <name>dfs.datanode.ipc.address</name>
      <value>0.0.0.0:52${PortPostfix}</value>
   </property>
</configuration>
EOF

cat >${HADOOP_CONF_DIR}/yarn-site.xml <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
	<property>
		<name>yarn.nodemanager.aux-services</name>
		<value>mapreduce_shuffle</value>
	</property>
	<property>
		<name>yarn.nodemanager.aux-services.mapreduce.shuffle.class</name>
      <value>org.apache.hadoop.mapred.ShuffleHandler</value>
	</property>
	<property>
		<name>yarn.nodemanager.vmem-pmem-ratio</name>
		<value>3</value>
	</property>
	<property>
		<name>yarn.nodemanager.delete.debug-delay-sec</name>
		<value>600</value>
	</property>
	<property>
		<name>yarn.nodemanager.vmem-check-enabled</name>
		<value>false</value>
	</property>
   <!-- DataNode X Konfiguration (eigene Ports) -->
   <property>
      <name>yarn.nodemanager.address</name>
      <value>0.0.0.0:53${PortPostfix}</value>
   </property>
   <property>
      <name>yarn.nodemanager.webapp.address</name>
      <value>0.0.0.0:54${PortPostfix}</value>
   </property>
   <property>
      <name>yarn.nodemanager.webapp.https.address</name>
      <value>0.0.0.0:55${PortPostfix}</value>
   </property>
   <property>
       <name>yarn.nodemanager.localizer.address</name>
       <value>0.0.0.0:56${PortPostfix}</value>
   </property>
   <!-- IMPORTANT: set this parameter to use Yarn and not local mode for computation -->
   <property>
      <name>yarn.resourcemanager.hostname</name>
      <value>${NameNodeIP}</value>
   </property>
</configuration>
EOF

echo "successfully prepared specific environment for Hadoop in ${HADOOP_CONF_DIR}"
echo "Ports to use are: 51${PortPostfix}, 52${PortPostfix} and 58${PortPostfix}"
echo "datanodes are started by namenode and executing ~/datanode.env with specific config"
source ~/datanode.env

echo "HADOOP_CONF_DIR=${HADOOP_CONF_DIR}"
echo "HADOOP_PID_DIR=${HADOOP_PID_DIR}"
echo "HADOOP_LOG_DIR=${HADOOP_LOG_DIR}"

echo "take care, that on data node in .bashrc the case-lines after 'If not running interactively...' are outcommented"

# If not running interactively, don't do anything
#case $- in
#    *i*) ;;
#      *) return;;
#esac


exit $RetCode