---
author: Viorel Anghel @esolutions.ro
title: Over my shoulder: monitoring stack
date: Oct 14, 2019
---

# Over my shoulder
This will present a tour de force with many tools used in our setups:

- Vagrant, Cluster-ssh, Ansible 
- Glusterfs
- Docker, Rancher
- Prometheus, Grafana

---
# What do we want?
- a setup to experiment with grafana
- 3 VMs with Ubuntu, all running on our laptop
- you can use this setup to experiment with many other distributed systems
- based on rancher 1.x + docker + glusterfs

---
# The monitoring stack
- we'll use https://github.com/stefanprodan/dockprom
- this will setup Prometheus and Grafana
- and will produce nice graphs both for VMs and for docker containers

---
# Requirements
I have tested all this on a Linux laptop with 16GB RAM and the following installed:
- VirtualBox
- Vagrant
- Ansible

---
# Vagrant intro
- Vagrant is a tool for building and managing virtual machine**S**
- focus on easy-to-use and automation
- works on Linux, Windows, MacOS
- Vagrant vs Terraform
- Vagrant works with VirtualBox (and other providers)

---
# Vagrantfile and commands
```bash
cd vagrant1
less Vagrantfile
vagrant status
vagrant up
vagrant ssh box1
    ... exit
vagrant destroy
```

---
# Preparing a three VMs setup
- discuss Vagrantfile
- discuss bootstrap.sh file
- get your ssh public key in this directory with the name id_rsa.pub
- discuss etc_hosts file

---
#  Creating and using the three VMs setup
- run ```vagrant up```
- other options: ```vagrant status | reload | provison```
- to access one node: ```vagrant ssh node1```
- or even better:
```
# setup local /etc/hosts so now you can
ssh root@node1
```

---
# The mighty cluster-ssh
```bash
# apt-get install cluster-ssh
cssh root@node{1,2,3}
```

---
# Using Ansible
- cd ansible
- discuss ansible.cfg
- discuss hosts
- run
```bash
ansible all -m ping
ansible all -m shell -a "uptime"
```

---
# Install docker on all nodes
- what is docker
- discuss docker.yml

```bash
ansible-playbook docker.yml
ssh root@node1 "docker ps"
```

---
# Install and setup glusterfs
- what is glusterfs
- discuss gluster*yml

```bash
ansible-playbook gluster-client.yml
ansible-playbook gluster-server.yml
```
---
# Setup gluster server
Run on a single node
```bash
ssh root@node1
  gluster peer probe node2
  gluster peer probe node3
  gluster peer status

  gluster volume create vol0 replica 3 arbiter 1 node1:/gluster/volume0 node2:/gluster/volume0 node3:/gluster/volume0
  gluster volume info vol0
```

# Mount the gluster volume
On all nodes, mount the gluster volume:
```bash
  cssh root@node{1,2,3}
    echo 'node1:vol0 /persistence glusterfs defaults 0 0' >>/etc/fstab
    mount -a
    #mount -t glusterfs node1:vol0 /persistence
    touch /persistence/test
    ls -la /persistence
```

---
# Setup rancher server
- we'll use Rancher version 1.6
- install on a single node with external Mysql database, as described here: 
https://rancher.com/docs/rancher/v1.6/en/installing-rancher/installing-server/#single-container-external-database

---
# Setup Mysql for Rancher server
```bash
ssh root@node1
  apt install mysql-server
  vi .mysqlpass
  chmod 600 .mysqlpass
  mysql -p$(head -1 /root/.mysqlpass)

  # ensure mysql is listening on all interfaces
  grep -r 127.0.0.1 /etc/mysql
  vi /etc/mysql/mysql.conf.d/mysqld.cnf # bind-address
  systemctl restart mysql-server
```

---
# Prepare Rancher db and start Rancher server
```bash
mysql -p$(head -1 /root/.mysqlpass)
  mysql> CREATE DATABASE IF NOT EXISTS cattle COLLATE = 'utf8_general_ci' CHARACTER SET = 'utf8';
  mysql> GRANT ALL ON cattle.* TO 'cattle'@'%' IDENTIFIED BY 'cattle';
  mysql> GRANT ALL ON cattle.* TO 'cattle'@'localhost' IDENTIFIED BY 'cattle';
```

And now start the rancher server version 1.6.x:
```bash
docker run -d --restart=unless-stopped -p 8080:8080 rancher/server:v1.6 --db-host node1 --db-port 3306 --db-user  cattle --db-pass cattle --db-name cattle
```
Watch it starting with ```docker ps``` and ```docker logs -f```.

---
# Rancher web interface
- go to rancher interface at http://node1:8080
- setup
- ignore authentication for now 
- add hosts node2 and node3

---
# The monitoring stack
- everything in the directory dock prim is based on https://github.com/stefanprodan/dockprom
- this works very well in a setup with docker only (without rancher). for rancher I had to do some minor changes in
  - docker-compose.yml
  - docker-compose.exporters.yml
  - prometheus/prometheus.yml
- also some changes for volumes in /persistence setup:

```bash
ssh root@node1 "mkdir -p /persistence/monitoring-stack/{grafana_data,prometheus_data} ; chmod 777 /persistence/monitoring-stack/{grafana_data,prometheus_data}"

for d in alertmanager caddy grafana prometheus ; do rsync -av $d/ root@node1:/persistence/monitoring-stack/$d/ ; done
```

---
# Create and start stacks in rancher
- in web interface create the stack monitoring-clients from ```docker-compose.exporters.yml```
- in rancher interface create the stack monitoring stack from ```docker-compose.yml```

# Optional a loadbalancer stack
- in rancher interface create a stack load-balancer
	- add a load balancer
		- "always run ... on every host"
		- name: port3000
		- port rules: port 3000 -> monitoring-stack/caddy


---
# Access grafana
Now finally, access grafana at 
- http://node2:3000 or 
- http://node3:3000 with admin:admin.

Enjoy the graphs!


