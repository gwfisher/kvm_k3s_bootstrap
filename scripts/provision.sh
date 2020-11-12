#!/bin/bash

sudo dnf update
sudo yum -y install podman podman-docker container-tools

# Now the fun stuff....container deployment!
sudo curl -sfL https://get.k3s.io | sh -
cd /tmp
tar xvf app1.tar.gz
cd /tmp/app1
sudo podman build --tag amazee-app1 .
sudo /usr/local/bin/kubectl apply -f /tmp/app1/app.yml

# Time for a smoke break ()____)__________@ - Yes, I kinda do ASCII art. Kinda