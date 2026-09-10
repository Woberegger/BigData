# BigData01 - prepare OpenStack system for BigData lecture


Howto taken roughly from gook "Big data in der Praxis" and following 2 links<br>
[how-to-install-hadoop-in-stand-alone-mode-on-ubuntu-20-04](https://www.digitalocean.com/community/tutorials/how-to-install-hadoop-in-stand-alone-mode-on-ubuntu-20-04) or<br>
[how-to-install-apache-hadoop-on-ubuntu-22-04](https://tecadmin.net/how-to-install-apache-hadoop-on-ubuntu-22-04/)


## install necessary system packages
```bash
sudo -s
```

```bash
apt update
apt -y install pdsh
```

tools, which make sense or are necessary for analysis etc.
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
# to be on save side for backwards compatibility we install versions 11 and 17, although Hadoop 3.5+ should fully support Java 17 (and 21 on clients)
export JAVA_FLAVOR=temurin-11-jdk
apt -y install $JAVA_FLAVOR
export JAVA_FLAVOR=temurin-17-jdk
apt -y install $JAVA_FLAVOR
```

openjdk-21-jdk is not compatible version with Hadoop 3.4.x and 3.5.x, so we use an older one (11 for 3.4.x and 17 for 3.5.x)

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
# depending on the computer's architecture, the output of "dpkg --print-architecture" will be either "amd64" or "arm64" or ...
# (if "dpkg" command should not work, you can try "uname -m" to get information about the architecture, e.g. x86_64 is amd64)
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

allow-password-based login for the student user
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

continue with script 01b_install_hadoop.md ...