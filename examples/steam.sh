#!/usr/bin/env bash
set -e

# An example of steam packaging in a RunImage container

if [ ! -x 'runimage' ]
    then
        echo '== download base RunImage'
        curl -o runimage -L "https://github.com/VHSgunzo/runimage/releases/download/continuous/runimage-$(uname -m)"
        chmod +x runimage
fi

run_install() {
    set -e

    INSTALL_PKGS=(
        steam egl-wayland vulkan-radeon lib32-vulkan-radeon vulkan-tools vulkan-intel
        lib32-vulkan-intel vulkan-nouveau lib32-vulkan-nouveau vulkan-swrast lib32-vulkan-swrast
        lib32-libpipewire libpipewire pipewire lib32-libpipewire libpulse lib32-libpulse
        vulkan-mesa-layers lib32-vulkan-mesa-layers freetype2 lib32-freetype2
    )

    echo '== checking for updates'
    rim-update

    echo '== install packages'
    pac --needed --noconfirm -S "${INSTALL_PKGS[@]}"

    echo '== install glibc with patches for Easy Anti-Cheat (optionally)'
    yes|pac -S glibc-eac lib32-glibc-eac

    echo '== shrink (optionally)'
    rim-shrink --all

    echo '== create RunImage config for app (optionally)'
    echo \
'RIM_CMPRS_LVL="${RIM_CMPRS_LVL:=22}"
RIM_CMPRS_BSIZE="${RIM_CMPRS_BSIZE:=22}"

RIM_SYS_NVLIBS="${RIM_SYS_NVLIBS:=1}"

RIM_SHARE_ICONS="${RIM_SHARE_ICONS:=1}"
RIM_SHARE_FONTS="${RIM_SHARE_FONTS:=1}"
RIM_SHARE_THEMES="${RIM_SHARE_THEMES:=1}"' \
> "$RUNDIR/config/steam.rcfg"

    echo '== Build new DwarFS runimage with zstd 22 lvl and 24 block size'
    rim-build -d -c 22 -b 24 steam.RunImage
}
export -f run_install

##########################

# enable OverlayFS mode, disable Nvidia driver check and run install steps
RIM_OVERFS_MODE=1 RIM_NO_NVIDIA_CHECK=1 \
./runimage bash -c run_install
