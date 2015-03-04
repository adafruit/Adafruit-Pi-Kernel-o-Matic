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
   echo "install.sh must be run as root. try: sudo install.sh"
   exit 1
fi

# via: http://stackoverflow.com/a/5196108
function exitonerr {

  "$@"
  local status=$?

  if [ $status -ne 0 ]; then
    echo "Error completing: $1" >&2
    exit 1
  fi

  return $status

}

echo "**** Installing custom kernel ****"
exitonerr dpkg -i raspberrypi-bootloader*
exitonerr dpkg -i libraspberrypi0*
exitonerr dpkg -i libraspberrypi-*
echo "**** Kernel install complete! ****"
echo

./dtc.sh -@ -I dts -O dtb -o /boot/overlays/pitft28r-overlay.dtb pitft28r-overlay.dts

if ! grep -Fq "pitft28r" /boot/config.txt; then
cat << "EOF" >> /boot/config.txt
device_tree=bcm2709-rpi-2-b.dtb
dtparam=spi=on
dtparam=i2c1=on
dtparam=i2c_arm=on
dtoverlay=pitft28r
dtdebug=1
EOF
fi

read -p "Reboot to apply changes? (y/n): " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
  reboot
fi
