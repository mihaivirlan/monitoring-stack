#!/bin/bash

exec >/tmp/bootstrap.log
#pwd # /home/vagrant
#id  # uid=0

cd /vagrant

# setup some swap space
if [ ! -f /swapfile ]
then
     fallocate -l 256M /swapfile || dd if=/dev/zero of=/swapfile bs=1M count=256
     chmod 600 /swapfile
     mkswap /swapfile
     swapon /swapfile
     echo '/swapfile swap swap defaults 0 0' >>/etc/fstab
     sysctl vm.swappiness=10
     echo 'vm.swappiness=10' >>/etc/sysctl.conf
fi	

# add the public ssh key to root
mkdir -p /root/.ssh
chmod 700 /root/.ssh
cat id_rsa.pub >>/root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys

# setup /etc/hosts
cp etc_hosts /etc/hosts

# install python for ansible
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y python

# install java
apt-get install -y openjdk-8-jre-headless

