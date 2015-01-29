#!/usr/bin/env bash

apt-get install -y git unzip build-essential libncurses5-dev

# symlink the build script
rm /usr/sbin/adabuild
rm -rf /kernel_builder
mv /home/vagrant/kernel_builder /kernel_builder
ln -s /kernel_builder/build.sh /usr/sbin/adabuild
