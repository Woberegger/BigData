# BigData01 - ssh key creation and distribution

This script needs to be executed by each student individually, as it depends on the individual host names, IP addresses and ssh keys
## adapt hosts settings for other nodes

```bash
sudo -s
```

```bash
echo "$(hostname -I | cut -d' ' -f1) namenode $(hostname)" >>/etc/hosts
```

the following 2 lines were already added in advance, when having created the base image
>echo "10.77.17.48 datanode1" >>/etc/hosts<br>
>echo "10.77.18.25 datanode2" >>/etc/hosts

it makes sense to clone the github repo to the OpenStack VM, as then all scripts, sources, config files etc. are there
(in some howtos we will expect, that this is exactly located, where set here)
```bash
su - hduser
```
```bash
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
```

we need to set one IP-address specific environment line as hduser, when we share datanodes
```bash
# IMPORTANT: that our installation works with shared secondary Datanodes, we have to prepare the namenode accordingly
export NAMENODEIP=$(hostname -I | cut -d' ' -f1)
ln -s /usr/local/hadoop/etc/hadoop /usr/local/hadoop/etc/datanode${NAMENODEIP}
#
cat >>~/.bashrc <<EOF
# specifically necessary because of shared datanodes
export HADOOP_CONF_DIR=\$HADOOP_INSTALL/etc/datanode${NAMENODEIP}
EOF

source ~/.bashrc
```
continue with script 01d_start_and_test_hadoop.md ...