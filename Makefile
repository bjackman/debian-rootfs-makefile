# This is a Makefile to build a Debian rootfs that is handy for fiddling around
# with VMs

# Optional - set up proxy for APT - not tested recently:
# Do the steps in here:
# https://medium.com/where-the-flamingcow-roams/apt-caching-for-debootstrap-bac499deebd5
# Then edit /etc/squid-deb-proxy/squid-deb-proxy.conf to enable all access (to
# be safe, a good idea to uninstall squid-deb-proxy when you're done)
# This should allow debootstrap and seup_debian9.sh to use cached debian
# packages.

# Need qemu-img in $PATH
# apt install debootstrap
#
# You also need to have sudo permission, unfortunately. I got as far as running
# debootstrap and creating the initial image (debian9_base.img) without root
# using fakeroot+fakechroot+fuse-ext2. But... it crashed my laptop so I gave up
# :(
# Maybe it could be done without root using OpenStack's disk-image-create tools,
# but they're quite confusing, I've never really figured it out.

# Try to clean up if recipes fail. Unfortunately it won't unmount stuff so this
# doesn't really work, but it helps for some stuff.
.DELETE_ON_ERROR:

all: debian9.img

# This creates a filesystem image with the default result of debootstrap.
debian9_base.img:
	qemu-img create $@ 1g
	mkfs.ext2 $@
	chmod a+w $@ # Otherwise kernel might refuse to mount rw
	mkdir mountpoint.dir
	sudo mount -o dev,exec,rw,loop $@ mountpoint.dir
	sudo --preserve-env debootstrap --arch amd64 stretch mountpoint.dir
	sudo umount mountpoint.dir
	rmdir mountpoint.dir

# This takes a default filesystem image and does customisation on it, producing
# a separate filesystem image. The reason for breaking this into two steps is
# that we can have this step depend on setup_debian9.sh, without having to
# re-run debootstrap (which takes ages) when it's modified.
debian9.img: debian9_base.img setup_debian9.sh
	cp $< $@
	chmod a+w $@ # Otherwise kernel might refuse to mount rw
	mkdir mountpoint.dir
	sudo mount -o rw,loop $@ mountpoint.dir
	sudo cp setup_debian9.sh mountpoint.dir
	sudo --preserve-env chroot mountpoint.dir /setup_debian9.sh
	sudo umount mountpoint.dir
	rmdir mountpoint.dir
