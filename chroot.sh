#!/usr/bin/env bash
#
# The MIT License (MIT)
#
# Copyright (c) 2015-2017 Adafruit
# # Permission is hereby granted, free of charge, to any person obtaining a copy
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
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE # AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
function print_help() {
    echo "Usage: $0 -t [pitfttype] -i target.img -a kernel.tar.gz"
    echo "    -h            Print this help"
    echo "    -t [type]     Specify the type of PiTFT: '28r' (PID 1601) or '28c' (PID 1983) or '35r' or '22'"
    echo "    -i [target]   Specify an ISO to perform install on (a recent Pi Foundation Raspbian)"
    echo "    -a [archive]  Specify a .tar.gz archive containing the new kernel and bootloader"
    echo
    echo "You must specify a type of display."
    exit 1
}

args=$(getopt -uo 'ht:i:a:' -- $*)
[ $? != 0 ] && print_help
set -- $args

for i
do
      case "$i"
      in
            -h)
                    print_help
                    ;;
            -t)
                    pitfttype="$2"
                    echo "Type = ${2}"
                    shift
                    shift
                    ;;
            -i)
                    target_image="$2"
                    echo "Image = ${2}"
                    shift
                    shift
                    ;;
            -a)
                    target_archive="$2"
                    echo "Archive = ${2}"
                    shift
                    shift
                    ;;
      esac
done

if [[ $EUID -ne 0 ]]; then
    echo "$0 must be run as root. try: sudo $0"
    exit 1
fi

if  [ "${pitfttype}" != "28r" ] && [ "${pitfttype}" != "28c" ] && [ "${pitfttype}" != "35r" ] && [ "${pitfttype}" != "22" ]
then
    echo "Type must be '28r' (2.8\" resistive, PID 1601) or '28c' (2.8\" capacitive, PID 1983)  or '35r' (3.5\" Resistive) or '22' (2.2\" no touch)"
    print_help
fi

target_mnt="/media/raspbian-target"
date=$(basename $target_image | cut -c1-10)
archive_name=$(basename $target_archive)

if [[ $target_image == *"lite"* ]]; then
  postfix="-lite"
else
  postfix=""
fi

echo "copying ${target_image}..."
cp $target_image "${date}-pitft-${pitfttype}${postfix}.img"
target_image="${date}-pitft-${pitfttype}${postfix}.img"

echo "resizing ${target_image}..."
dd if=/dev/zero bs=1M count=500 >> $target_image
P_START=$( fdisk -lu $target_image | grep Linux | awk '{print $2}' ) # Start of 2nd partition in 512 byte sectors
P_SIZE=$(( $( fdisk -lu $target_image | grep Linux | awk '{print $3}' ) * 1024 )) # Partition size in bytes
losetup /dev/loop2 $target_image -o $(($P_START * 512))
fsck -f /dev/loop2
resize2fs /dev/loop2
fsck -f /dev/loop2
losetup -d /dev/loop2
echo -e "p\nd\n2\nn\np\n2\n$P_START\n\np\nW\n" | fdisk $target_image

# assemble a mostly-legit filesystem by mounting / and /boot from the target
# iso, plus /dev from the host pi (/dev/(u)random seems to be required by
# recent versions of GPG):
echo "Mounting $target_image on $target_mnt"
kpartx -av $target_image
mkdir -p $target_mnt
mount /dev/dm-1 $target_mnt
mount /dev/dm-0 $target_mnt/boot
mkdir -p $target_mnt/dev
mount --bind /dev $target_mnt/dev

cp /usr/bin/qemu-arm-static $target_mnt/usr/bin
cp $target_archive $target_mnt/tmp
mv $target_mnt/etc/ld.so.preload $target_mnt/etc/ld.so.preload.bak
echo "" > $target_mnt/etc/ld.so.preload

chroot $target_mnt mkdir -p /tmp/pitft_kernel
chroot $target_mnt tar xf /tmp/$archive_name -C /tmp/pitft_kernel --strip-components=1
chroot $target_mnt rm /tmp/$archive_name

echo "Adding apt.adafruit.com to sources.list"
curl -SLs https://apt.adafruit.com/add | chroot $target_mnt /bin/bash

# pin apt.adafruit.com origin for anything installed there:
echo -e "Package: *\nPin: origin \"apt.adafruit.com\"\nPin-Priority: 1001" | chroot $target_mnt bash -c "cat > /etc/apt/preferences.d/adafruit"

echo "Installing kernel and adafruit-pitft-helper"
chroot $target_mnt /bin/bash -c 'sudo dpkg -i /tmp/pitft_kernel/raspberrypi*'
chroot $target_mnt /bin/bash -c 'sudo rm -rf /tmp/pitft_kernel/raspberrypi*'
chroot $target_mnt /bin/bash -c 'sudo dpkg -i /tmp/pitft_kernel/libraspberrypi*'
chroot $target_mnt /bin/bash -c 'sudo rm -rf /tmp/pitft_kernel/libraspberrypi*'
chroot $target_mnt sudo apt-get install -y adafruit-pitft-helper

echo "Running adafruit-pitft-helper"
chroot $target_mnt /bin/bash -c "printf 'y\ny\ny\n' | sudo adafruit-pitft-helper -t $pitfttype"

mv $target_mnt/etc/ld.so.preload.bak $target_mnt/etc/ld.so.preload
rm $target_mnt/usr/bin/qemu-arm-static

echo "Unmounting $target_image"
umount $target_mnt/boot
umount $target_mnt/dev
umount $target_mnt
kpartx -d $target_image

echo "shrinking image..."
P_START=$( fdisk -lu $target_image | grep Linux | awk '{print $2}' ) # Start of 2nd partition in 512 byte sectors
P_SIZE=$(( $( fdisk -lu $target_image | grep Linux | awk '{print $3}' ) * 1024 )) # Partition size in bytes
losetup /dev/loop2 $target_image -o $(($P_START * 512))
fsck -f /dev/loop2
resize2fs -M /dev/loop2 # Make the filesystem as small as possible
fsck -f /dev/loop2
P_NEWSIZE=$( dumpe2fs /dev/loop2 2>/dev/null | grep '^Block count:' | awk '{print $3}' ) # In 4k blocks
P_NEWEND=$(( $P_START + ($P_NEWSIZE * 8) + 1 )) # in 512 byte sectors
losetup -d /dev/loop2
echo -e "p\nd\n2\nn\np\n2\n$P_START\n$P_NEWEND\np\nW\n" | fdisk $target_image
I_SIZE=$((($P_NEWEND + 1) * 512)) # New image size in bytes
truncate -s $I_SIZE $target_image

zipname=$(basename $target_image .img)
echo "compressing $target_image"
zip "${zipname}.zip" $target_image

echo "moving ${zipname}.zip to your host machine..."
rm -f $target_image
mv "${zipname}.zip" "/vagrant/${zipname}.zip"
