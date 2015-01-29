#!/usr/bin/env bash

GIT_DIR="/ada_linux"
MOD_DIR=`mktemp -d`
PKG_DIR=`mktemp -d`
TOOLS_DIR="/rpi_tools"

GIT_REPO="--branch rpi-3.15.y --single-branch https://github.com/adafruit/adafruit-raspberrypi-linux"

if [ "$1" == "" ]; then
  echo "Warning: Repo argument not supplied, using: ${GIT_REPO}"
else
  # use temp dir if we aren't using adafruit's linux repo
  GIT_DIR=`mktemp -d`
  git clone --depth 1 --recursive $GIT_REPO $GIT_DIR
fi

if [ ! -d $TOOLS_DIR ]; then
  echo "**** CLONING TOOL REPO ****"
  git clone --depth 1 https://github.com/raspberrypi/tools $TOOLS_DIR
fi

cd $TOOLS_DIR
git pull

CCPREFIX=${TOOLS_DIR}/arm-bcm2708/arm-bcm2708-linux-gnueabi/bin/arm-bcm2708-linux-gnueabi-

if [ ! -d $GIT_DIR ]; then
  echo "**** CLONING GIT REPO ****"
  git clone --depth 1 --recursive $GIT_REPO $GIT_DIR
fi

cd $GIT_DIR
git reset --hard origin/master
git submodule update --init
cp arch/arm/configs/bcmrpi_defconfig .config

echo "**** COMPILING KERNEL ****"
ARCH=arm CROSS_COMPILE=${CCPREFIX} make menuconfig
ARCH=arm CROSS_COMPILE=${CCPREFIX} make -k
ARCH=arm CROSS_COMPILE=${CCPREFIX} INSTALL_MOD_PATH=${MOD_DIR} make modules_install

# bump the control version
OLD_VERSION=$(grep "^Version: *" /kernel_builder/package/DEBIAN/control | sed "s/Version: //;")
read -e -p "Enter the new version: " -i "${OLD_VERSION}" NEW_VERSION
sed -i /kernel_builder/package/DEBIAN/control -e "s/^Version/${NEW_VERSION}/"

cp -r /kernel_builder/package/* $PKG_DIR
cp ${GIT_DIR}/arch/arm/boot/Image $PKG_DIR/boot/kernel.img 
cp -r ${MOD_DIR}/lib ${PKG_DIR}

echo "**** BUILDING DEB PACKAGE ****"
fakeroot dpkg-deb -b $PKG_DIR /tmp/raspberrypi-bootloader-adafruit_${NEW_VERSION}.deb
