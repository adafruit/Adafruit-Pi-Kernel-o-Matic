#!/usr/bin/env bash
#
# The MIT License (MIT)
#
# Copyright (c) 2015-2017 Adafruit
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

function print_help() {
    echo "Usage: $0 -i target.img -a kernel.tar.gz"
    echo "    -h            Print this help"
    echo "    -i [target]   Specify an ISO to perform install on (a recent Pi Foundation Raspbian)"
    echo "    -a [archive]  Specify a .tar.gz archive containing the new kernel and bootloader"
    echo
    echo "You must specify a target image and a kernel archive."
    exit 1
}

args=$(getopt -uo 'hi:a:' -- $*)
[ $? != 0 ] && print_help
set -- $args

for i
do
      case "$i"
      in
            -h)
                    print_help
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

adachroot -t 22 -i $target_image -a $target_archive
adachroot -t 28r -i $target_image -a $target_archive
adachroot -t 28c -i $target_image -a $target_archive
adachroot -t 35r -i $target_image -a $target_archive
