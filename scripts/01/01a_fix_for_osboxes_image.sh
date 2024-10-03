# the following is necessary when using the osboxes image for Ubuntu 22-10, as the repository has changed meanwhile
# therefore only important, when working with VmWare or VirtualBox virtualisation and only with certain versions!
sudo cp /etc/apt/sources.list /etc/apt/sources.list.bak 
sudo sed -i -re 's/([a-z]{2}.)?archive.ubuntu.com|security.ubuntu.com/old-releases.ubuntu.com/g' /etc/apt/sources.list
sudo apt-get update
