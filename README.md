# Kernel-o-Matic for Adafruit PiTFT

![kernel-o-matic](/docs/pngn_kernelomatic_with_logos.gif?raw=true)

## Setup

Clone the Kernel-o-Matic repo:

```sh
$ git clone git@github.com:adafruit/Adafruit-Pi-Kernel-o-Matic.git
$ cd Adafruit-Pi-Kernel-o-Matic
```

Check out the `pitft` branch:

```sh
$ git checkout pitft
```

Install Vagrant and VirtualBox:
* [Vagrant][vagrant]
* [VirtualBox][vb]

Run the following to start the Vagrant box and SSH in:

```sh
$ vagrant up && vagrant ssh
```
## Creating a New Branch Based on an Upstream Branch

This example will move PiTFT changes from `rpi-4.4.y` to `rpi-4.9.y`. This step is not needed if you are building an existing branch.

First, you will need to [add a new SSH key to GitHub for the vagrant box][keys]. Then, clone the Adafruit Raspberry Pi Linux repo into the vagrant home directory:

```sh
$ git clone git@github.com:adafruit/adafruit-raspberrypi-linux.git
$ cd adafruit-raspberrypi-linux
```

Add the Raspberry Pi Linux repo as a git remote named `upstream`:

```sh
$ git remote add upstream git@github.com:raspberrypi/linux.git
```

Fetch the branch list from `upstream`:

```sh
$ git fetch upstream
```

Create a new local branch from the target `rpi-4.9.y` branch from upstream:

```sh
$ git checkout -b rpi-4.9.y upstream/rpi-4.9.y
```

Push the new branch to `adafruit/adafruit-raspberrypi-linux` aka `origin`:

```sh
$ git push -u origin rpi-4.9.y
```

## Adding Changes to the New Branch

We will be using `rpi-4.4.y` as our source branch and `rpi-4.9.y` as the new branch again in this example. If the files have diverged, you will need to manually merge them using your favorite text editor. If the files haven't changed much in the new branch, we can move them from `rpi-4.4.y` by using the following command:

```sh
$ git checkout rpi-4.4.y path/to/file.c
```

If you would like to see the diff before commiting, you will need to unstage the changes using `git reset`:

```sh
$ git reset
$ git diff
```

If you are happy with the changes, commit them and push them up to GitHub:

```sh
$ git add -A
$ git commit
$ git push
```

Repeat this process for all files in the **"Files Changed"** tab in the [compare view on GitHub for your old branch][compare].

## Building .deb packages

To build `.deb` packages, you can now use `adabuild` to build the new `rpi-4.9.y` branch:

```sh
$ sudo adabuild -b rpi-4.9.y
```

`menuconfig` will automatically be lauched twice in this process. Once for armv6, and once for armv7. At the time of writing, these are the modules that needed to be enabled:

```
CONFIG_GPIO_STMPE=y
CONFIG_RPI_POWER_SWITCH=m
CONFIG_TOUCHSCREEN_FT6X06=m
```

When the build process has finished, you should see a message like the one below:

```
THE adafruit_pitft_kernel_1.20170517-1.tar.gz ARCHIVE SHOULD NOW BE
AVAILABLE IN THE KERNEL-O-MATIC FOLDER ON YOUR HOST MACHINE
```

On your host machine (mac os, windows, etc), check the Kernel-o-Matic folder for the new `.deb` file. If it's not present, check the `adabuild` output for any build errors.

## Building Images

You will need to download the latest version of Jessie Lite in the vagrant instance:

```sh
$ cd ~
$ wget https://downloads.raspberrypi.org/raspbian_lite_latest && mv raspbian_lite_latest raspbian_lite_latest.zip
$ unzip raspbian_lite_latest.zip
Archive:  raspbian_lite_latest.zip
  inflating: 2017-04-10-raspbian-jessie-lite.img
```

You will see a `.img` filename like the one seen above in the output of `unzip`. In this example we will be using `2017-04-10-raspbian-jessie-lite.img`. To modify
an image for a specific type of PiTFT, you can use the `adachroot` helper script. This example will make a copy of the source `.img` and install the supplied kernel
and bootloader for the 2.8" resistive PiTFT.

```sh
sudo adachroot -t 28r -i 2017-04-10-raspbian-jessie-lite.img -a /vagrant/adafruit_pitft_kernel_1.20170517-1.tar.gz
```

After the image is finished, you will see a message like the one below:

```sh
moving 2017-04-10-pitft-28r-lite.zip to your host machine...
```

On your host machine (mac os, windows, etc), check the Kernel-o-Matic folder for the new `.img` file. If it's not present, check the `adachroot` output for any build errors.

You can also build images for all types of PiTFTs with the `adaimage` command:

```sh
sudo adaimage -i 2017-04-10-raspbian-jessie-lite.img -a /vagrant/adafruit_pitft_kernel_1.20170517-1.tar.gz
```

[vagrant]: https://www.vagrantup.com/
[vb]: https://www.virtualbox.org/wiki/Downloads
[keys]: https://help.github.com/articles/adding-a-new-ssh-key-to-your-github-account/#platform-linux
[ada-linux]: https://github.com/adafruit/adafruit-raspberrypi-linux
[compare]: https://github.com/raspberrypi/linux/compare/rpi-4.4.y...adafruit:rpi-4.4.y
