#!/usr/bin/env bash
set -e

ARCH=$(uname -m)

export RIM_NO_NVIDIA_CHECK=1

# musl has a little DNS crap
export RIM_UNSHARE_RESOLVCONF=1

if [ ! -x runimage ]
    then
        curl -L https://github.com/VHSgunzo/runimage/releases/download/continuous/runimage-$ARCH -o runimage
        chmod +x runimage
fi

rm -rf rootfs
./runimage getdimg -x rootfs alpine:latest
chmod u+rw -R rootfs

echo -e 'options timeout:2 attempts:3/nnameserver 1.1.1.1\nnameserver 8.8.8.8' > rootfs/etc/resolv.conf

RIM_ROOT=1 ./runimage apk add bash coreutils curl findutils gawk grep iproute2 kmod procps-ng sed \
tar util-linux which gocryptfs libnotify lsof slirp4netns socat xhost gzip xz zstd lz4 jq binutils \
patchelf nftables iptables openresolv iputils file fakeroot dbus||true

curl -L https://raw.githubusercontent.com/VHSgunzo/runimage-fake-sudo-pkexec/refs/heads/main/usr/bin/sudo \
    -o rootfs/usr/bin/sudo && chmod +x rootfs/usr/bin/sudo

./runimage rim-shrink --back --docs --locales --pkgcache --pycache

./runimage rim-build runimage-alpine -c 22 -b 24

chmod u+rw -R rootfs
rm -rf rootfs

#########################

rm -rf RunDir
mkdir -p RunDir/config

./runimage-alpine bash -c '/var/RunDir/sharun/lib4bin -k -p -s -g -d RunDir/sharun $(cat /var/RunDir/sharun/bin.list) ; \
    cp /var/RunDir/sharun/bin.list RunDir/sharun/ ; \
    cp /var/RunDir/sharun/bin/.version RunDir/sharun/bin/ ; \
    (cd RunDir && ln -sf sharun/bin static)'

mkdir -p RunDir/rootfs/etc
mkdir -p RunDir/rootfs/usr/lib
./runimage-alpine bash -c 'cp -fr /etc/ssl RunDir/rootfs/etc/'
echo -e 'options timeout:2 attempts:3/nnameserver 1.1.1.1\nnameserver 8.8.8.8' > RunDir/rootfs/etc/resolv.conf

./runimage-alpine bash -c 'cp -f /var/RunDir/sharun/lib4bin RunDir/sharun/ ; \
    cp -f /var/RunDir/sharun/bin/{bwrap,chisel,ssrv,tini,unionfs,uruntime,cpids} RunDir/sharun/bin/ ; \
    (cd RunDir/sharun/bin && for bin in {dwarfs,dwarfsck,dwarfsextract,mkdwarfs,mksquashfs,squashfuse,unsquashfs}; \
        do ln -sf uruntime "$bin"; done) ; \
    cp -fr /var/RunDir/{utils,Run,Run.sh} RunDir/'

./runimage-alpine getdimg -x RunDir/rootfs busybox:musl

RIM_ROOTFS=RunDir/rootfs ./RunDir/Run rim-shrink --back --docs --locales --pkgcache --pycache

mkdir -p RunDir/config
echo 'RIM_UNSHARE_RESOLVCONF="${RIM_UNSHARE_RESOLVCONF:=1}"' > RunDir/config/Run.rcfg

./RunDir/Run rim-build runimage-busybox -c 22 -b 24

chmod u+rw -R RunDir
rm -rf RunDir
