# BigData01 - prepare docker in WSL

This script first installs the necessary programs to use Docker containers inside WSL2

Enable Docker in WSL

```bash
apt-get update
apt-get -y install apt-transport-https ca-certificates curl gnupg-agent software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt-get update
apt-get -y install docker-ce docker-ce-cli containerd.io docker-compose-plugin docker-compose make
```

Start the Docker service

```bash
service docker start
```

The following command should then work, but will find nothing yet because we haven't installed any containers

```bash
docker ps -a
```

The image, the download command and configuration instructions can be found at [](https://hub.docker.com/search?q=nginx)

As a test we install the nginx webserver so we can immediately see whether ports from the container can be used on the host

```bash
docker pull nginx
```

downloads around 48MB and creates an image of 188MB, so not too big - we can anyway delete it later

Optionally check beforehand using
```bash
netstat -an
```
on Windows, which ports are occupied by other tools and containers; 8080 is often in use, so I used 8081

```bash
docker run --name nginx -d -p 8081:80 nginx
```

Then please enter the following line in the browser on Windows; it should display
>"Welcome to nginx!"

[](http://localhost:8081/)

If this works, the Docker installation in WSL2 is successful and we can continue with the other exercises.