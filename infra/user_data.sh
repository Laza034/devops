#!/bin/bash
sudo su -
yum install docker -y
systemctl start docker
docker run -d -p 8080:8080 laza034/devops:multistage