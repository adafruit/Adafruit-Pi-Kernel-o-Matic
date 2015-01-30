# Raspberry Pi Kernel-o-Matic

![kernel-o-matic](/docs/pngn_kernelomatic_with_logos.png?raw=true)

![kernel-o-matic](/docs/pngn_kernelomatic_with_logos.png?raw=true)

## Compiling The Raspbian Kernel

Clone the git repo & start the vagrant box:

```
$ git clone git@github.com:adafruit/Pi_vagrant.git
$ cd Pi_vagrant
$ vagrant up
```

Once the vagrant box is up, SSH in:

```
$ vagrant ssh
```

Now that you are connected to the VM, check out the help for a list of options:

```
~$ sudo adabuild -h
usage: adabuild [options]
 This will build the Raspberry Pi Kernel.
 OPTIONS:
    -h        Show this message
    -r        The remote git repo to clone
              Default: https://github.com/raspberrypi/linux
    -b        The git branch to use
              Default: rpi-3.15.y
    -c        The config file to use when compiling
              Default: arch/arm/configs/bcmrpi_defconfig
```

Compile with default options:

```
~$ sudo adabuild
```

Compile [adafruit-raspberrypi-linux][1] using the `rpi-3.15.y` branch:

```
~$ sudo adabuild -r https://github.com/adafruit/adafruit-raspberrypi-linux -b rpi-3.15.y
```

[1]: https://github.com/adafruit/adafruit-raspberrypi-linux
