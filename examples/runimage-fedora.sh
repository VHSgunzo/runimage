#!/usr/bin/env bash
set -e

ARCH=$(uname -m)

export RIM_NO_NVIDIA_CHECK=1

if [ ! -x runimage ]
    then
        curl -L https://github.com/VHSgunzo/runimage/releases/download/continuous/runimage-$ARCH -o runimage
        chmod +x runimage
fi

rm -rf rootfs
./runimage getdimg -x rootfs fedora:latest

echo -e 'nameserver 1.1.1.1\nnameserver 8.8.8.8' > rootfs/etc/resolv.conf

RIM_ROOT=1 ./runimage sh -c 'yum copr enable nucleo/gocryptfs -y && yum update -y ; \
yum install -y bash coreutils curl findutils gawk grep iproute kmod procps-ng sed \
tar util-linux which gocryptfs libnotify lsof slirp4netns socat xhost gzip xz zstd \
lz4 jq binutils patchelf nftables iptables-nft openresolv iputils fakeroot fakechroot file'||true

curl -L https://raw.githubusercontent.com/VHSgunzo/runimage-fake-sudo-pkexec/refs/heads/main/usr/bin/sudo \
    -o rootfs/usr/bin/sudo && chmod +x rootfs/usr/bin/sudo

curl -sL https://github.com/VHSgunzo/runimage-fake-nvidia-driver/raw/refs/heads/main/fake-nvidia-driver.tar|\
    tar -xvf- -C rootfs

./runimage rim-shrink --back --docs --locales --pkgcache --pycache
rm -rf rootfs/var/cache/libdnf*/*

./runimage rim-build runimage-fedora -c 22 -b 24

chmod u+rw -R rootfs
rm -rf rootfs
