
BOX_COUNT=3
BOX_MEMORY=2048

Vagrant.configure(2) do |config|
#  config.vm.box = "ubuntu/xenial64"
  config.vm.box = "ubuntu/bionic64"
  config.vm.synced_folder ".", "/vagrant", disabled: false

  config.vm.provider "virtualbox" do |v|
    v.memory = BOX_MEMORY
    v.cpus = 2
  end

  (1..BOX_COUNT).each do |i|
    config.vm.define "node#{i}" do |node|
      node.vm.hostname = "node#{i}"
      node.vm.network "private_network", ip: "192.168.133.1#{i}"
      node.vm.provision "shell", path: "./bootstrap.sh"
    end
  end
end

