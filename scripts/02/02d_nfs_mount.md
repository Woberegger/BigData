# BigData02 - HDFS NFS Mount (voluntary task)

search for a possibility to mount hdfs filesystems e.g. in NFS<br>
(instructions at [](https://hadoop.apache.org/docs/stable/hadoop-project-dist/hadoop-hdfs/HdfsNfsGateway.html)<br>
or by using fuse as described under [](https://cwiki.apache.org/confluence/display/HADOOP2/MountableHDFS)

the following howto was tested on openstack platform:

the changes in the xml configuration files widely allow call connects (in a productive environment these should be restricted to specific hosts and groups)

a) in core-site.xml
```vim
	<property>
	  <name>hadoop.proxyuser.hduser.groups</name>
	  <value>*</value>
	</property>
	<property>
	  <name>hadoop.proxyuser.hduser.hosts</name>
	  <value>*</value>
	</property>
	<property>
	  <name>hadoop.proxyuser.root.groups</name>
	  <value>*</value>
	</property>
	<property>
	  <name>hadoop.proxyuser.root.hosts</name>
	  <value>*</value>
	</property>
```

b) in hdfs-site.xml:
```vim
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
```

then install rpcbind and nfs-common packages, start rpcbind and nfs-common services
```bash
sudo apt install -y rpcbind
sudo systemctl start rpcbind
sudo apt install -y nfs-common
sudo /etc/init.d/nfs-common start
rpcinfo -p $(hostname)
```

then restart hdfs, it should additionally start the nfs3 daemon
```bash
su - hduser
stop-dfs.sh
start-dfs.sh
hdfs --daemon start nfs3
```

or optionally start in foreground using call "hdfs nfs3"
(especially if the following call does not find anything, the start in the foreground will show the error output)
```bash
jps | grep Nfs3
```

finally mount the hdfs via nfs on the local machine
```bash
sudo mkdir /mnt/hdfs
sudo mount -t nfs -o vers=3,proto=tcp,nolock,noacl,sync localhost:/ /mnt/hdfs
```

and you should be able to see the hdfs content there, e.g. recursively list the whole hdfs filesystem

```bash
ls -lsR /mnt/hdfs
```


