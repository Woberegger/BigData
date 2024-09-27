#!/bin/bash

datadir=`echo $HDFS_CONF_dfs_datanode_data_dir | perl -pe 's#file://##'`
if [ ! -d $datadir ]; then
  echo "Datanode data directory not found: $datadir"
  exit 2
fi

$HADOOP_HOME/bin/hdfs datanode -format -clusterID CID-608081f7-54c7-498d-9adc-7da5ad095ca
$HADOOP_HOME/bin/hdfs --config $HADOOP_CONF_DIR datanode
