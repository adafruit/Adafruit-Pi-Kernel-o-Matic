#!/usr/bin/env bash

apt-get install -y git unzip build-essential gcc-4.4-arm-linux-gnueabi libncurses5-dev

# make sure gcc is in the right place
if [ ! -f /usr/bin/arm-linux-gnueabi-gcc ]; then
  ln -s /usr/bin/arm-linux-gnueabi-gcc-4.4 /usr/bin/arm-linux-gnueabi-gcc
fi

# symlink the build script
if [ ! -f /usr/sbin/adabuild ]; then
  ln -s /kernel_builder/build.sh /usr/sbin/adabuild
fi
