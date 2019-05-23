This is my hacky Makefile for throwing together a Debian rootfs image that's
handy for mucking around with in VMs. There are probably proper tools for doing
all this stuff, and some of them probably don't need root. QCOW2 images would
probably be better too.

Unfortunately it uses sudo so you'll have to babysit and feed it your password.

Basically it first runs debootstrap to get a totally raw Debian image. This
takes absolutely ages, so it then saves that in an intermediate file and takes a
copy of it. Then it loop-mounts the copy, chroots into it, and runs
setup_debian9.sh to add a load of nice stuff to turn it from a raw Debian system
into a sort-of-usable Linux rootfs.
