#!/bin/bash

# Check if docker is installed
if [ -x "$(command -v docker)" ]; then
  echo "Docker had been installed"
  exit 0
else
  echo "Installing docker..."
fi

# Install docker v20.10.6
export docker_version=20.10.6
sudo apt-get remove docker docker-engine docker.io containerd runc -y
sudo apt-get update
sudo apt-get -y install apt-transport-https ca-certificates \
  curl software-properties-common bash-completion gnupg-agent
sudo curl -fsSL http://mirrors.aliyun.com/docker-ce/linux/ubuntu/gpg |
  sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] http://mirrors.aliyun.com/docker-ce/linux/ubuntu \
    $(lsb_release -cs) stable"
sudo apt-get -y update
version=$(apt-cache madison docker-ce | grep ${docker_version} | awk '{print $3}')
sudo apt-get -y install docker-ce=${version} --allow-downgrades
sudo systemctl enable docker

# Deploy docker daemon.json
(
  cat <<EOF
{
  "storage-driver": "overlay2",
  "max-concurrent-downloads": 3,
  "max-concurrent-uploads": 5,
  "log-driver": "json-file",
  "log-opts": {
      "max-size": "100m",
      "max-file": "3"
  }
}
EOF
) >/etc/docker/daemon.json
sudo systemctl restart docker

# Install docker-compose
if [ -x "$(command -v docker-compose)" ]; then
  echo "Docker-compose had been installed"
else
  echo "Installing docker-compose..."
  sudo cp -r ./docker/docker-compose /usr/local/bin/
  sudo chmod +x /usr/local/bin/docker-compose
  docker-compose -v
fi

# Grant docker permissions to ordinary users
sudo groupadd docker
sudo cat /etc/group | grep docker
sudo gpasswd -a ${USER} docker
cat /etc/group
sudo systemctl restart docker
sudo chmod a+rw /var/run/docker.sock
docker info

echo "Success"
