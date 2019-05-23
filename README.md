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

You can then use it by doing this sort of thing:

```
sudo apt install qemu seabios ipxe-qemu qemu-kvm

sudo usermod -aG kvm $USER # So you have /dev/kvm access
su $USER                   # So the above takes effect

# Set KERNEL_IMG to point to a Linux bzImage
# Set ROOTFS_IMG to point to debian9.img produced by the Makefile here
# Set HOST_SHARE to a directory you want to expose to the guest as a plan9 share

qemu-system-x86_64 \
    -L /usr/share/seabios/ -L /usr/lib/ipxe/qemu/ \
    -machine pc-q35-2.5,accel=kvm,usb=off \
    -m 2G \
    -smp $(nproc) \
    --nographic \
    -kernel $KERNEL_IMG \
    -append "root=/dev/sda console=ttyS0" \
    -drive file=$ROOTFS_IMG,index=0,media=disk,format=raw,if=none,id=drive-sata0-0-0 \
    -device ide-hd,bus=ide.1,drive=drive-sata0-0-0,id=sata0-0-0,bootindex=1 \
    -device e1000,netdev=network0 \
    -netdev user,id=network0,hostfwd=tcp::5555-:22 \
    -fsdev local,security_model=passthrough,id=fsdev0,path=$HOST_SHARE \
    -device virtio-9p-pci,id=fs0,fsdev=fsdev0,mount_tag=hostshare
```
