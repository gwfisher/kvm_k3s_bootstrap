#!/bin/bash

sudo dnf update
sudo yum -y install podman podman-docker container-tools

sudo curl -sfL https://get.k3s.io | sh -