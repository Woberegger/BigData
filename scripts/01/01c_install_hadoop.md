# BigData01 - install hadoop

Anleitung im Grundgerüst entnommen aus "Big data in der Praxis" oder z.B. von<br>
[](https://www.digitalocean.com/community/tutorials/how-to-install-hadoop-in-stand-alone-mode-on-ubuntu-20-04) oder<br>
[](https://tecadmin.net/how-to-install-apache-hadoop-on-ubuntu-22-04/)


## install necessary system packages
```bash
sudo -s
apt update
apt -y install pdsh
```

tools, which make sense
```bash
apt -y install inetutils-telnet
apt -y install nmap
apt -y install curl
apt -y install wget
apt -y install vim
apt -y install vim-gtk3 # necessary on Debian image, where vim is built without clipboard support ("vim --version | grep clipboard")
apt -y install net-tools
apt -y install git
apt -y install gpg # needed for apt keys to add
```

**IMPORTANT: in order that paste with mouse in vim works on Debian (for all users), you have to call the following<br>
(or optionally change user's .vimrc)**
```bash
echo "set clipboard=unnamedplus" >>/etc/vim/vimrc.local # allow mouse-paste
echo "syntax on" >>/etc/vim/vimrc.local # enable coloured syntax highlighting
```

on debian this is strange, we have to force to use the global settings in the user environments
```bash
su - debian -c "echo 'source /etc/vim/vimrc' >~debian/.vimrc"
echo 'source /etc/vim/vimrc' >/root/.vimrc
```

## install and configure Java
we need to download older Java version from a different repository as the current one (as Debian "Trixie" only contains Java versions 21+, but hadoop 3.x.x only supports Java 8+11)
```bash
mkdir -m 0755 -p /etc/apt/keyrings/
wget -O - https://packages.adoptium.net/artifactory/api/gpg/key/public > /etc/apt/keyrings/adoption.gpg
echo "deb [signed-by=/etc/apt/keyrings/adoption.gpg] https://packages.adoptium.net/artifactory/deb trixie main" >/etc/apt/sources.list.d/adoptium.list
# "apt update" should find e.g. https://packages.adoptium.net/artifactory/deb package
apt update 
export JAVA_FLAVOR=temurin-11-jdk
apt -y install $JAVA_FLAVOR
```

openjdk-21-jdk is not compatible version with Hadoop 3.4.x, so we use an older one

call the following for java runtime and compiler to use the proper version
if more than 1 Java version is installed, please select Java 11
```bash
update-alternatives --config java
update-alternatives --config javac
#verify, that /etc/alternatives/java points to correct java version
ls -lsa /etc/alternatives/java
```

additionally create symbolic link for java version, so that following environment settings are easier
```bash
cd /usr/lib/jvm/
# abhängig von der Rechnerarchitektur könnte die Ausgabe von "dpkg --print-architecture" amd64 oder arm64 oder ??? liefern
# wenn dpkg Befehl nicht funktioniert, liefert auch "uname -m" Info zur Architektur, die jedoch dann interpretiert werden muss, da z.B. x86_64 als amd64 zu interpretieren ist
ln -sf ${JAVA_FLAVOR}-$(dpkg --print-architecture) jdk
```

also set JAVA_HOME in global profile
```bash
echo "export JAVA_HOME=/usr/lib/jvm/${JAVA_FLAVOR}-$(dpkg --print-architecture)" >/etc/profile.d/java.sh
export SSH_PORT=22
echo "export SSH_PORT=$SSH_PORT" >>/etc/profile.d/java.sh
chmod 644 /etc/profile.d/java.sh
```

## adapt ssh login and create/configure necessary users

allow-password-based login für the student user
```bash
cat >/etc/ssh/sshd_config.d/10-student.conf <<EOF
Match User student
   PasswordAuthentication yes
EOF
```

>Question: What do the || mean in the following call?
```bash
systemctl reload ssh || systemctl start ssh || service ssh start
```

add user and group for hadoop - **IMPORTANT: under this user all BigData tools will run**
(we set password "hadoop" for user "hduser")
```bash
groupadd hadoop
useradd -g hadoop -s /bin/bash -m hduser
echo "hduser:hadoop" | chpasswd # allows to change password by script
# add hduser to sudoers group
adduser hduser sudo
```

## adapt hosts settings for other nodes
```bash
echo "$(hostname -I | cut -d' ' -f1) namenode" >>/etc/hosts
```

the following 2 lines were already added in advance, when having created the base image
>echo "10.77.17.48 datanode1" >>/etc/hosts<br>
>echo "10.77.18.25 datanode2" >>/etc/hosts

it makes sense to clone the github repo to the OpenStack VM, as then all scripts, sources, config files etc. are there
(in some howtos we will expect, that this is exactly located, where set here)
```bash
su - hduser
echo 'source /etc/vim/vimrc' >~/.vimrc
git clone https://github.com/Woberegger/BigData
```

## create and distribute SSH keys
needed for communication between e.g. namenode and datanodes, even locally
```bash
ssh-keygen -t rsa -P ""
cat ~/.ssh/id_rsa.pub  > ~/.ssh/authorized_keys
# copy keys to the 2 additional datanodes
ssh-copy-id -i ~/.ssh/id_rsa.pub hduser@datanode1
ssh-copy-id -i ~/.ssh/id_rsa.pub hduser@datanode2
```

If you get asked for password, then the key exchange did not work!!!
(the flag -o omits the SSH trust question - this shall only be used on a local trusted system,
otherwise answer with "yes", if you are asked to trust the key)
```bash
ssh -o StrictHostKeyChecking=accept-new localhost "ls -lsa"
```

connect to different aliases, as some config might use the alias "namenode"
```bash
ssh -o StrictHostKeyChecking=accept-new $(hostname) "ls -lsa"
ssh -o StrictHostKeyChecking=accept-new namenode "ls -lsa"
## exit or Ctrl<d> to return back to original user (as "hduser" is not per default in sudo group)
exit
```

## Download and install Hadoop
download it in suitable version (best take the one listed here, which was tested)
```bash
sudo -s
cd /usr/local
export HADOOP_VERSION=3.4.1
wget https://dlcdn.apache.org/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz --no-check-certificate
wget https://downloads.apache.org/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz.sha512 --no-check-certificate
```

it is good practice to verify, that a download is not corrupt or was manipulated
(the ShaSum File references a different file name, therefore it has to be corrected with "sed")
optional call "shasum -a 512 hadoop-${HADOOP_VERSION}.tar.gz" and manually cross-check the output against *.sha512 file
```bash
sed -i 's/-RC1//' hadoop-${HADOOP_VERSION}.tar.gz.sha512
shasum -a 512 hadoop-${HADOOP_VERSION}.tar.gz -c hadoop-${HADOOP_VERSION}.tar.gz.sha512
```

unpack the archive and generate a link, so that after a later version update only the link needs to be changed
```bash
tar -xzf hadoop-${HADOOP_VERSION}.tar.gz
# or in 2 steps: gzip -d hadoop-${HADOOP_VERSION}.tar.gz && tar -xf hadoop-${HADOOP_VERSION}.tar
ln -sf hadoop-${HADOOP_VERSION} hadoop
```

the user "hduser" will be the "master" of that directory
```bash
chown -R hduser:hadoop hadoop*
```

## configure hadoop

set environment variables in .bashrc of user "hduser"

```bash
su - hduser
# IMPORTANT: that our installation works with shared secondary Datanodes, we have to prepare the namenode accordingly
export NAMENODEIP=$(hostname -I | cut -d' ' -f1)
ln -s /usr/local/hadoop/etc/hadoop /usr/local/hadoop/etc/datanode${NAMENODEIP}
export JAVA_FLAVOR=temurin-11-jdk
```

fill environment file .bashrc with system variables
>Question: What are the Backslash-Quotes used for?

```bash
cat >>~/.bashrc <<EOF
# Java (a copy of what is already in /etc/profile.d/java.sh)
export JAVA_HOME=/usr/lib/jvm/${JAVA_FLAVOR}-$(dpkg --print-architecture)

export HADOOP_INSTALL=/usr/local/hadoop
export HADOOP_HOME=\$HADOOP_INSTALL
# specifically necessary because of shared datanodes
export HADOOP_CONF_DIR=\$HADOOP_INSTALL/etc/datanode${NAMENODEIP}
export HADOOP_MAPRED_HOME=\$HADOOP_INSTALL
export HADOOP_COMMON_HOME=\$HADOOP_INSTALL
export HADOOP_HDFS_HOME=\$HADOOP_INSTALL
export HADOOP_YARN_HOME=\$HADOOP_INSTALL
export HADOOP_COMMON_LIB_NATIVE_DIR=\$HADOOP_INSTALL/lib/native
export HADOOP_OPTS="-Djava.library.path=\$HADOOP_INSTALL/lib/native"
export YARN_HOME=\$HADOOP_HOME

export PATH=\$PATH:\$JAVA_HOME/bin:\$HADOOP_INSTALL/bin:\$HADOOP_INSTALL/sbin

export PDSH_RCMD_TYPE=ssh
EOF
```

as the content, which was now appended to .bashrc, will only be interpreted upon new login,
we have to either re-login or read it with "source" command.
>Question: What is the source command for? Why do we not simply call .bashrc? Does .bashrc have executable rights?

```bash
source ~/.bashrc
```

### adapt Hadoop configuration files (as user "hduser")

unfortunately this is also needed here (and not sufficient in .bashrc)
```bash
echo "export JAVA_HOME=/usr/lib/jvm/${JAVA_FLAVOR}-$(dpkg --print-architecture)" >>${HADOOP_HOME}/etc/hadoop/hadoop-env.sh
```

here we better take common configuration files, so that all have the same settings initially:

adapt /usr/local/hadoop/etc/hadoop/core-site.xml: Settings for the HDFS distributed file system
```bash
cat >${HADOOP_CONF_DIR}/hdfs-site.xml <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
   <property>
      <name>dfs.replication</name>
      <value>2</value>
   </property>
   <property>
      <name>dfs.namenode.maintenance.replication.min</name>
      <value>1</value>
   </property>
   <property>
      <name>dfs.namenode.hosts.provider.classname</name>
      <value>org.apache.hadoop.hdfs.server.blockmanagement.CombinedHostFileManager</value>
   </property>
   <property>
      <name>dfs.hosts</name>
      <value>/usr/local/hadoop/etc/hadoop/hosts</value>
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
      <value>file:/usr/local/hadoop/hadoopdata/hdfs/datanode</value>
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
</configuration>
EOF
```

adapt /usr/local/hadoop/etc/hadoop/core-site.xml: Settings for hadoop in general<br>
*(in order to later have identical configuration files between primary and other nodes, we use logical name "namenode"
instead of "localhost") - this name has to exist in /etc/hosts, e.g. "namenode"*
```bash
cat >${HADOOP_CONF_DIR}/core-site.xml <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
	<property>
		<name>fs.defaultFS</name>
		<value>hdfs://namenode:9000</value>
	</property>
	<property>
		<name>hadoop.tmp.dir</name>
		<value>/usr/local/hadoop/hadoopdata/hdfs/tmp</value>
	</property>
</configuration>
EOF
```

adapt /usr/local/hadoop/etc/hadoop/mapred-site.xml: Settings for Map Reduce jobs
```bash
cat >${HADOOP_CONF_DIR}/mapred-site.xml <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
   <property>
      <name>mapreduce.shuffle.port</name>
      <value>13562</value>
   </property>
   <property>
      <name>mapreduce.job.tracker</name>
      <value>namenode:9001</value>
   </property>
   <property>
      <name>mapreduce.jobhistory.address</name>
      <value>namenode:10020</value>
   </property>
   <property>
      <name>mapreduce.jobhistory.webapp.address</name>
      <value>namenode:19888</value>
   </property>   
   <!-- IMPORTANT: with value "yarn" all NodeManager processes on all datanodes must correctly talk to Namenode (only with "yarn" the jobhistory is on port 8088 is available)
                   therefore better use "local", this should always work -->
   <property>
      <name>mapreduce.framework.name</name>
      <value>local</value>
   </property>
</configuration>
EOF
```

adapt /usr/local/hadoop/etc/hadoop/yarn-site.xml: Settings for yarn Ressource manager
```bash
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
   <!-- IMPORTANT: set this parameter to use Yarn and not local mode for computation -->
   <property>
      <name>yarn.resourcemanager.hostname</name>
      <value>namenode</value>
   </property>
</configuration>
EOF
```

### create necessary directories in the "normal" file system, which Hadoop uses (as user "hduser")
```bash
mkdir -p /usr/local/hadoop/hadoopdata/hdfs/tmp
mkdir -p /usr/local/hadoop/hadoopdata/hdfs/namenode
mkdir -p /usr/local/hadoop/hadoopdata/hdfs/datanode
mkdir -p /usr/local/hadoop/hadoopdata/hdfs/input
```

### initially (!) format the HDFS File Systems and start
(as user "hduser")
```bash
hdfs namenode -format
```

start hadoop and yarn (as hduser)
```bash
start-dfs.sh
start-yarn.sh
```

optionally this works also with individual daemons, especially to debug it, if one process should not start up properly
```bash
#hdfs --daemon   start namenode
#hdfs --daemon   start datanode
#hdfs --daemon   start secondarynamenode
#yarn --daemon   start resourcemanager
#yarn --daemon   start nodemanager
#mapred --daemon start historyserver
```

Check, if all expected processes are running
```bash
jps | sort -k2
```

expected output are the following 6 java processes (of course with different PID)
>7444 DataNode<br>
>8129 Jps<br>
>7290 NameNode<br>
>7958 NodeManager<br>
>6024 ResourceManager<br>
>7642 SecondaryNameNode<br>

if there exists a problem like *No such rcmd module "ssh"* it may be necessary to additionally install package "pdsh-rcmd-ssh"!

### show status in Web GUI
locally on your laptop start your preferred browser (replace "ip_of_VM" with your VM's particular IP address)
a) for hadoop: [](http://<ip_of_VM>:9870)
b) for yarn: [](http://<ip_of_VM>:8088)

in case of problems best look into the logfiles located under /usr/local/hadoop/logs

finally stop yarn and hadoop (as user "hduser")
```bash
stop-yarn.sh 
stop-dfs.sh
```

again stopping (like starting) can also be done individually with each individual process daemon
```bash
#hdfs --daemon stop namenode
#hdfs --daemon stop datanode
#hdfs --daemon stop secondarynamenode
#yarn --daemon stop nodemanager
#yarn --daemon stop resourcemanager
#mapred --daemon stop historyserver
```
