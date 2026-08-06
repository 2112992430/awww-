#!/bin/bash

pwd="$(realpath "$(dirname "$0")")"
source "$pwd/linux/jiasuqi.conf"

sudo qemu-system-x86_64 -enable-kvm -daemonize \
    -cpu host \
    -smp 2,sockets=1,cores=2,threads=1 \
    -drive file="$pwd/vm/windows.img",if=virtio \
    -net nic,model=virtio \
    -net tap,ifname=$INTERFACE,script="$pwd/linux/vm-up.sh",downscript="$pwd/linux/vm-down.sh" \
    -m 2G \
    -object memory-backend-file,id=mem,size=2G,mem-path=/dev/shm,share=on \
    -numa node,memdev=mem \
    -chardev socket,id=char0,path=/tmp/vhostqemu \
    -device vhost-user-fs-pci,queue-size=1024,chardev=char0,tag=shared_win \
    -vga virtio \
    -spice addr=127.0.0.1,port=$SPICE_PORT,disable-ticketing \
    -machine usb=on \
    -device usb-tablet \
    -device virtio-serial \
    -chardev spicevmc,id=vdagent,name=vdagent \
    -device virtserialport,chardev=vdagent,name=com.redhat.spice.0 \
    "$@"

exec remote-viewer --title Windows spice://127.0.0.1:$SPICE_PORT

