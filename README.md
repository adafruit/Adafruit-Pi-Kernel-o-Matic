# Adafruit's Raspberry Pi Kernel-o-Matic

![kernel-o-matic](/docs/pngn_kernelomatic_with_logos.gif?raw=true)

A detailed guide for using the Kernel-o-Matic can be found on
[The Adafruit Learning System][1]. If you are familiar with Vagrant and
VirtualBox, a brief overview of the build process can be found below.

If you are looking to compile a custom kernel with the PiTFT device tree overlays included,
you can do that by using the [pitft branch][3] of this repo.

## Compiling The Raspberry Pi Kernel

Clone the git repo & start the vagrant box:

```
$ git clone https://github.com/adafruit/Adafruit-Pi-Kernel-o-Matic.git Kernel-o-Matic
$ cd Kernel-o-Matic
$ vagrant up
```

Once the vagrant box is up, SSH in:

```
$ vagrant ssh
```

Now that you are connected to the VM, use `-h` for a list of options:

```
~$ sudo adabuild -h
usage: adabuild [options]
 This will build the Raspberry Pi Kernel.
 OPTIONS:
    -h        Show this message
    -r        The remote github kernel repo to clone in user/repo format
              Default: raspberrypi/linux
    -b        The git branch to use
              Default: Default git branch of repo
    -1        The config file to use when compiling for Raspi v1
              Default: arch/arm/configs/bcmrpi_defconfig
    -2        The config file to use when compiling for Raspi v2
              Default: arch/arm/configs/bcm2709_defconfig
```

Compile with default options:

```
~$ sudo adabuild
```

Compile [adafruit-raspberrypi-linux][2] using the `rpi-3.15.y` branch:

```
~$ sudo adabuild -r https://github.com/adafruit/adafruit-raspberrypi-linux -b rpi-3.15.y
```

A `tar.gz` archive will be available in the Kernel-o-Matic folder on the host machine
after the custom kernel has been built. Copy the archive to your Pi and extact the
contents. Installation instructions are included in the archive.

[1]: https://learn.adafruit.com/raspberry-pi-kernel-o-matic
[2]: https://github.com/adafruit/adafruit-raspberrypi-linux
[3]: https://github.com/adafruit/Adafruit-Pi-Kernel-o-Matic/tree/pitft
