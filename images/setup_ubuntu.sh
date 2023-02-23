#!/bin/sh
set -e

SCRIPT=$(basename "$0")

echo "[INFO] [${SCRIPT}] Setup docker"
sudo apt-get update
sudo apt-get install \
  ca-certificates \
  curl \
  gnupg \
  lsb-release

sudo mkdir -m 0755 -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo chmod a+r /etc/apt/keyrings/docker.gpg
sudo apt-get update
sudo apt-get install -y docker-ce
sudo usermod -a -G docker ubuntu

sudo mkdir -p /etc/docker
sudo tee -a /etc/docker/daemon.json > /dev/null << EOF
{
  "dns": ["172.17.0.1"]
}
EOF

sudo mkdir -p /etc/systemd/resolved.conf.d
sudo tee -a /etc/systemd/resolved.conf.d/consul.conf > /dev/null << EOF
[Resolve]
DNS=127.0.0.1:8600
DNSSEC=no
Domains=~consul.
EOF

sudo tee -a /etc/systemd/resolved.conf.d/docker.conf > /dev/null << EOF
[Resolve]
DNSStubListener=yes
DNSStubListenerExtra=172.17.0.1
EOF

# Install CNI plugins
curl -L -o /tmp/cni-plugins.tgz "https://github.com/containernetworking/plugins/releases/download/v1.2.0/cni-plugins-linux-$( [ $(uname -m) = aarch64 ] && echo arm64 || echo amd64)"-v1.2.0.tgz
sudo mkdir -p /opt/cni/bin
sudo tar -C /opt/cni/bin -xzf /tmp/cni-plugins.tgz

sudo tee -a /etc/sysctl.d/10-consul.conf > /dev/null << EOF
net.bridge.bridge-nf-call-arptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF

# Install Envoy
export ENVOY_VERSION_STRING=1.24.0
curl -L https://func-e.io/install.sh | sudo bash -s -- -b /usr/local/bin
func-e use $ENVOY_VERSION_STRING
sudo cp ~/.func-e/versions/$ENVOY_VERSION_STRING/bin/envoy /usr/local/bin/
