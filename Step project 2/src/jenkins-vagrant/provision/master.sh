#!/usr/bin/env bash
set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive

sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg lsb-release git

sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo $VERSION_CODENAME) stable" \
| sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

sudo systemctl enable --now docker
sudo usermod -aG docker vagrant || true

sudo docker volume create jenkins_home >/dev/null 2>&1 || true
sudo docker rm -f jenkins >/dev/null 2>&1 || true

sudo docker pull jenkins/jenkins:lts-jdk17
sudo docker run -d --name jenkins --restart=unless-stopped \
  -p 8080:8080 -p 50000:50000 \
  -v jenkins_home:/var/jenkins_home \
  jenkins/jenkins:lts-jdk17

echo "------------------------------------------------------------"
echo "Jenkins links:"
echo "  Host: http://localhost:8090"
echo "  VM:   http://192.168.56.10:8080"
echo "------------------------------------------------------------"

echo "Waiting initialAdminPassword..."
for i in $(seq 1 90); do
  if sudo docker exec jenkins test -f /var/jenkins_home/secrets/initialAdminPassword; then
    break
  fi
  sleep 2
done

echo "INITIAL ADMIN PASSWORD:"
sudo docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword || true
