#!/usr/bin/env bash
#
# The MIT License (MIT)
#
# Copyright (c) 2015 Adafruit
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

if [[ $EUID -ne 0 ]]; then
   echo "adabuild must be run as root. try: sudo adabuild"
   exit 1
fi

GIT_DIR="/rpi_linux"
V1_MOD_DIR=`mktemp -d`
V2_MOD_DIR=`mktemp -d`
PKG_DIR=`mktemp -d`
TOOLS_DIR="/opt/rpi_tools"
FIRMWARE_DIR="/opt/rpi_firmware"
NUM_CPUS=`nproc`
GIT_REPO="https://github.com/raspberrypi/linux"
GIT_BRANCH=""

V1_COMPILE_CONFIG="arch/arm/configs/bcmrpi_defconfig"
V2_COMPILE_CONFIG="arch/arm/configs/bcm2709_defconfig"

function usage() {
  cat << EOF
usage: adabuild [options]
 This will build the Raspberry Pi Kernel.
 OPTIONS:
    -h        Show this message
    -r        The remote git repo to clone
              Default: $GIT_REPO
    -b        The git branch to use
              Default: Default git branch of repo
    -1        The config file to use when compiling for Raspi v1
              Default: $V1_COMPILE_CONFIG
    -2        The config file to use when compiling for Raspi v2
              Default: $V2_COMPILE_CONFIG

EOF
}

function clone() {
  echo "**** CLONING GIT REPO ****"
  echo "REPO: ${GIT_REPO}"
  echo "BRANCH: ${GIT_BRANCH}"
  git clone --depth 1 --recursive $GIT_BRANCH ${GIT_REPO} $GIT_DIR
}

while getopts "hb:r:1:2:" opt; do
  case "$opt" in
  h)  usage
      exit 0
      ;;
  b)  GIT_BRANCH="--branch $OPTARG"
      ;;
  r)  GIT_REPO="$OPTARG"
      ;;
  1)  V1_COMPILE_CONFIG="$OPTARG"
      ;;
  2)  V2_COMPILE_CONFIG="$OPTARG"
      ;;
  \?) usage
      exit 1
      ;;
  esac
done

echo -e "\n**** USING ${NUM_CPUS} AVAILABLE CORES ****\n"

if [ "$GIT_REPO" != "https://github.com/raspberrypi/linux" ]; then
  # use temp dir if we aren't using the default linux repo
  GIT_DIR=`mktemp -d`
  clone
fi

if [ ! -d $TOOLS_DIR ]; then
  echo "**** CLONING TOOL REPO ****"
  git clone --depth 1 https://github.com/raspberrypi/tools $TOOLS_DIR
fi

if [ ! -d $FIRMWARE_DIR ]; then
  echo "**** CLONING FIRMWARE REPO ****"
  git clone --depth 1 https://github.com/raspberrypi/firmware $FIRMWARE_DIR
fi

# make sure tools dir is up to date
cd $TOOLS_DIR
git pull
CCPREFIX="${TOOLS_DIR}/arm-bcm2708/gcc-linaro-arm-linux-gnueabihf-raspbian/bin/arm-linux-gnueabihf-"

# make sure firmware dir is up to date
cd $FIRMWARE_DIR
git pull

# pull together the debian package folder
cp -r /kernel_builder/package/* $PKG_DIR
mkdir $PKG_DIR/boot
BOOT_FILES="bootcode.bin fixup.dat fixup_cd.dat fixup_x.dat kernel.img kernel7.img start.elf start_cd.elf start_x.elf"
for FN in $BOOT_FILES; do
  cp $FIRMWARE_DIR/boot/$FN $PKG_DIR/boot
done
mv $PKG_DIR/boot/kernel.img $PKG_DIR/boot/kernel_emergency.img
mv $PKG_DIR/boot/kernel7.img $PKG_DIR/boot/kernel7_emergency.img

# if we don't have a git dir, clone the repo
if [ ! -d $GIT_DIR ]; then
  clone
fi

# make sure we are up to date
cd $GIT_DIR
git pull
git submodule update --init

# RasPi v1 build
rm .config
make ARCH=arm clean
echo "**** CONFIGURING Pi v1 kernel USING ${V1_COMPILE_CONFIG} ****"
cp ${V1_COMPILE_CONFIG} .config
ARCH=arm CROSS_COMPILE=${CCPREFIX} make menuconfig
echo "**** SAVING A COPY OF YOUR v1 CONFIG TO /vagrant/v1_saved_config ****"
cp .config /vagrant/v1_saved_config
echo "**** COMPILING v1 KERNEL ****"
ARCH=arm CROSS_COMPILE=${CCPREFIX} make -j${NUM_CPUS} -k
ARCH=arm CROSS_COMPILE=${CCPREFIX} INSTALL_MOD_PATH=${V1_MOD_DIR} make -j${NUM_CPUS} modules_install
cp ${GIT_DIR}/arch/arm/boot/Image $PKG_DIR/boot/kernel.img

# RasPi v2 build
rm .config
make ARCH=arm clean
echo "**** CONFIGURING Pi v2 kernel USING ${V2_COMPILE_CONFIG} ****"
cp ${V2_COMPILE_CONFIG} .config
ARCH=arm CROSS_COMPILE=${CCPREFIX} make menuconfig
echo "**** SAVING A COPY OF YOUR v2 CONFIG TO /vagrant/v2_saved_config ****"
cp .config /vagrant/v2_saved_config
echo "**** COMPILING v2 KERNEL ****"
ARCH=arm CROSS_COMPILE=${CCPREFIX} make -j${NUM_CPUS} -k
ARCH=arm CROSS_COMPILE=${CCPREFIX} INSTALL_MOD_PATH=${V2_MOD_DIR} make -j${NUM_CPUS} modules_install
cp ${GIT_DIR}/arch/arm/boot/Image $PKG_DIR/boot/kernel7.img

# confirm package version
OLD_VERSION=`date +%Y%m%d`
read -e -p "Confirm the new version: " -i "1.${OLD_VERSION}-1" NEW_VERSION
sed -i $PKG_DIR/DEBIAN/control -e "s/^Version.*/Version: ${NEW_VERSION}/"

# copy the compiled modules to the package
cp -r ${V1_MOD_DIR}/lib ${PKG_DIR}
cp -r ${V2_MOD_DIR}/lib ${PKG_DIR}

echo "**** BUILDING DEB PACKAGE ****"
fakeroot dpkg-deb -b $PKG_DIR /vagrant/raspberrypi-bootloader-custom_${NEW_VERSION}.deb

echo -e "\n**** DONE: /vagrant/raspberrypi-bootloader-custom_${NEW_VERSION}.deb ****\n"

echo -e "THE raspberrypi-bootloader-custom_${NEW_VERSION}.deb PACKAGE SHOULD NOW BE\nAVAILABLE IN THE KERNEL-O-MATIC FOLDER ON YOUR HOST MACHINE\n\n"
