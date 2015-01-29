#!/usr/bin/env bash

apt-get install -y git unzip build-essential libncurses5-dev

BUILDER_DIR=`mktemp -d`

rm -rf /kernel_builder
git clone --depth 1 https://github.com/adafruit/Adafruit-Pi-Kernel-o-Matic $BUILDER_DIR
mv $BUILDER_DIR/scripts /kernel_builder

# symlink the build script
rm /usr/sbin/adabuild
ln -s /kernel_builder/build.sh /usr/sbin/adabuild
