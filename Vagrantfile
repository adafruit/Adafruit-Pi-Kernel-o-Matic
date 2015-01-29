# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  config.vm.box = "ubuntu/precise32"

  config.vm.network "public_network"

  config.vm.provider "virtualbox" do |vb|
    vb.gui = false
  end

  config.vm.synced_folder "scripts/", "/kernel_builder", owner: "root", group: "root"

  config.vm.provision "shell", path: "provision.sh"

end
