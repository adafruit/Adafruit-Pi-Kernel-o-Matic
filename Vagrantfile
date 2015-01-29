# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  config.vm.box = "ubuntu/precise32"

  config.vm.network "public_network"

  config.vm.provider "virtualbox" do |v|
    v.gui = false

    host = RbConfig::CONFIG['host_os']

    # via https://github.com/btopro/elmsln-vagrant/blob/master/Vagrantfile#L33
    # 1/4 system memory & all cpu cores
    if host =~ /darwin/
      cpus = `sysctl -n hw.ncpu`.to_i
      mem = `sysctl -n hw.memsize`.to_i / 1024 / 1024 / 4
    elsif host =~ /linux/
      cpus = `nproc`.to_i
      mem = `grep 'MemTotal' /proc/meminfo | sed -e 's/MemTotal://' -e 's/ kB//'`.to_i / 1024 / 4
    else # Windows ???
      cpus = 2
      mem = 1024
    end

    v.customize ["modifyvm", :id, "--memory", mem]
    v.customize ["modifyvm", :id, "--cpus", cpus]
    v.customize ["modifyvm", :id, "--ioapic", "on"]

  end

  config.vm.synced_folder "scripts/", "/kernel_builder", owner: "root", group: "root"

  config.vm.provision "shell", path: "provision.sh"

end
