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

REPO_ROOT="/kernel_repos/"
MOD_DIR=`mktemp -d`
PKG_TMP=`mktemp -d`
TOOLS_DIR="/opt/rpi_tools"
FIRMWARE_DIR="/opt/rpi_firmware"
DEBIAN_DIR="/opt/rpi_debian"
NUM_CPUS=`nproc`
GIT_REPO="raspberrypi/linux"
V1_DIR="${REPO_ROOT}${GIT_REPO}/v1"
V2_DIR="${REPO_ROOT}${GIT_REPO}/v2"
GIT_BRANCH=""

V1_DEFAULT_CONFIG="arch/arm/configs/bcmrpi_defconfig"
V2_DEFAULT_CONFIG="arch/arm/configs/bcm2709_defconfig"
V1_CONFIG=""
v2_CONFIG=""

function usage() {
  cat << EOF
usage: adabuild [options]
 This will build the Raspberry Pi Kernel.
 OPTIONS:
    -h        Show this message
    -r        The remote github repo to clone in user/repo format
              Default: $GIT_REPO
    -b        The git branch to use
              Default: Default git branch of repo
    -1        The config file to use when compiling for Raspi v1
              Default: $V1_DEFAULT_CONFIG
    -2        The config file to use when compiling for Raspi v2
              Default: $V2_DEFAULT_CONFIG

EOF
}

function clone() {
  echo "**** CLONING to ${REPO_ROOT}${GIT_REPO} ****"
  echo "REPO: ${GIT_REPO}"
  echo "BRANCH: ${GIT_BRANCH}"
  git clone --recursive https://github.com/${GIT_REPO} $V1_DIR
  cp -r $V1_DIR $V2_DIR
}

while getopts "hb:r:1:2:" opt; do
  case "$opt" in
  h)  usage
      exit 0
      ;;
  b)  GIT_BRANCH="$OPTARG"
      ;;
  r)  GIT_REPO="$OPTARG"
      ;;
  1)  V1_CONFIG="$OPTARG"
      ;;
  2)  V2_CONFIG="$OPTARG"
      ;;
  \?) usage
      exit 1
      ;;
  esac
done

echo -e "\n**** USING ${NUM_CPUS} AVAILABLE CORES ****\n"

if [ ! -d $REPO_ROOT ]; then
  mkdir $REPO_ROOT
fi

if [ "$GIT_REPO" != "raspberrypi/linux" ]; then

  if [[ "$GIT_REPO" =~ "http" ]]; then
      echo "please provide a valid githubuser/repo path"
      usage
      exit 1
  fi

  V1_DIR="${REPO_ROOT}${GIT_REPO}/v1"
  V2_DIR="${REPO_ROOT}${GIT_REPO}/v2"

fi

if [ ! -d $V1_DIR ]; then
  mkdir -p $V1_DIR
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

if [ ! -d $DEBIAN_DIR ]; then
  echo "**** CLONING DEBIAN BUILD REPO ****"
  git clone --depth 1 https://github.com/asb/firmware $DEBIAN_DIR
fi

# make sure tools dir is up to date
cd $TOOLS_DIR
git pull

# make sure firmware dir is up to date
cd $FIRMWARE_DIR
git pull

# make sure debian package dir is up to date
cd $DEBIAN_DIR
git pull

# pull together the debian package folder
CURRENT_DATE=`date +%Y%m%d`
NEW_VERSION="1.${CURRENT_DATE}"
PKG_DIR="${PKG_TMP}/raspberrypi-firmware_${NEW_VERSION}"
mkdir $PKG_DIR
cp -r $FIRMWARE_DIR/* $PKG_DIR
# mv $PKG_DIR/boot/kernel.img $PKG_DIR/boot/kernel_emergency.img
# mv $PKG_DIR/boot/kernel7.img $PKG_DIR/boot/kernel7_emergency.img

# RasPi v1 build
cd $V1_DIR
SUBDIRS=`find $V1_DIR -maxdepth 1 -type d | wc -l` #make sure the clone succeeded
if [ $SUBDIRS -eq 2 ]; then
    clone
fi
git pull
git checkout ${GIT_BRANCH}
git submodule update --init
CCPREFIX=${TOOLS_DIR}/arm-bcm2708/arm-bcm2708-linux-gnueabi/bin/arm-bcm2708-linux-gnueabi-
if [ ! -f .config ]; then
  if [ "$V1_CONFIG" == "" ]; then
    cp ${V1_DEFAULT_CONFIG} .config
  else
    cp ${V1_CONFIG} .config
  fi
fi
ARCH=arm CROSS_COMPILE=${CCPREFIX} make menuconfig
echo "**** SAVING A COPY OF YOUR v1 CONFIG TO /vagrant/v1_saved_config ****"
cp .config /vagrant/v1_saved_config
echo "**** COMPILING v1 KERNEL ****"
ARCH=arm CROSS_COMPILE=${CCPREFIX} make -j${NUM_CPUS} -k zImage modules dtbs
ARCH=arm CROSS_COMPILE=${CCPREFIX} INSTALL_MOD_PATH=${MOD_DIR} make -j${NUM_CPUS} modules_install
${TOOLS_DIR}/mkimage/mkknlimg arch/arm/boot/zImage $PKG_DIR/boot/kernel.img
cp -r ${MOD_DIR}/lib/* ${PKG_DIR}

# RasPi v2 build
cd $V2_DIR
git pull
git checkout ${GIT_BRANCH}
git submodule update --init
CCPREFIX=${TOOLS_DIR}/arm-bcm2708/gcc-linaro-arm-linux-gnueabihf-raspbian/bin/arm-linux-gnueabihf-
if [ ! -f .config ]; then
  if [ "$V2_CONFIG" == "" ]; then
    cp ${V2_DEFAULT_CONFIG} .config
  else
    cp ${V2_CONFIG} .config
  fi
fi
ARCH=arm CROSS_COMPILE=${CCPREFIX} make menuconfig
echo "**** SAVING A COPY OF YOUR v2 CONFIG TO /vagrant/v2_saved_config ****"
cp .config /vagrant/v2_saved_config
echo "**** COMPILING v2 KERNEL ****"
ARCH=arm CROSS_COMPILE=${CCPREFIX} make -j${NUM_CPUS} -k zImage modules dtbs
ARCH=arm CROSS_COMPILE=${CCPREFIX} INSTALL_MOD_PATH=${MOD_DIR} make -j${NUM_CPUS} modules_install
cp arch/arm/boot/dts/*.dtb $PKG_DIR/boot/
cp arch/arm/boot/dts/overlays/*.dtb* $PKG_DIR/boot/overlays/
cp arch/arm/boot/dts/overlays/README $PKG_DIR/boot/overlays/
${TOOLS_DIR}/mkimage/mkknlimg arch/arm/boot/zImage $PKG_DIR/boot/kernel7.img
cp -r ${MOD_DIR}/lib/* ${PKG_DIR}

cd $PKG_TMP
tar czf raspberrypi-firmware_${NEW_VERSION}.orig.tar.gz raspberrypi-firmware_${NEW_VERSION}

# copy debian files to package directory
cp -r $DEBIAN_DIR/debian $PKG_DIR
touch $PKG_DIR/debian/files
cd $PKG_DIR/debian
source gen_bootloader_postinst_preinst.sh

cd $PKG_DIR
dch -v ${NEW_VERSION}-1 --package raspberrypi-firmware 'Adds Adafruit Kernel-o-Matic custom kernel'
chown -R vagrant $PKG_TMP
su vagrant -c "debuild --no-lintian -ePATH=${PATH}:${TOOLS_DIR}/arm-bcm2708/gcc-linaro-arm-linux-gnueabihf-raspbian/bin -b -aarmhf -us -uc"

cd $PKG_TMP
mkdir custom_kernel_${NEW_VERSION}-1
cp *.deb custom_kernel_${NEW_VERSION}-1
cp /vagrant/install.sh custom_kernel_${NEW_VERSION}-1
cp /vagrant/docs/INSTALL custom_kernel_${NEW_VERSION}-1
chmod +x custom_kernel_${NEW_VERSION}-1/install.sh
tar czf custom_kernel_${NEW_VERSION}-1.tar.gz custom_kernel_${NEW_VERSION}-1
mv -f custom_kernel_${NEW_VERSION}-1.tar.gz /vagrant

echo -e "THE custom_kernel_${NEW_VERSION}-1.tar.gz ARCHIVE SHOULD NOW BE\nAVAILABLE IN THE KERNEL-O-MATIC FOLDER ON YOUR HOST MACHINE\n\n"
