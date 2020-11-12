#!/bin/bash

sudo dnf update
sudo yum -y install podman podman-docker container-tools

# Now the fun stuff....container deployment!
sudo curl -sfL https://get.k3s.io | sh -
tar xvfz /tmp/app1.tar.gz
cd /tmp/app1
sudo podman build --tag amazee-app1 .
sudo /usr/local/bin/kubectl apply -f ./app1.yml