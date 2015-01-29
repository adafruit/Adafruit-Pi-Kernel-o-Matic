#!/usr/bin/env bash

apt-get install -y git unzip build-essential libncurses5-dev

# symlink the build script
if [ ! -f /usr/sbin/adabuild ]; then
  ln -s /kernel_builder/build.sh /usr/sbin/adabuild
fi
