#!/usr/bin/env bash

DEVELOPERS="VHSgunzo"
export RUNIMAGE_VERSION='0.38.3'

RED='\033[1;91m'
BLUE='\033[1;94m'
GREEN='\033[1;92m'
YELLOW='\033[1;33m'
RESETCOLOR='\033[1;00m'

SYS_PATH="$PATH"
export RUNPPID="$PPID"
export RUNPID="$BASHPID"
RPIDSFL="/tmp/.rpids.$RUNPID"
BWINFFL="/tmp/.bwinf.$RUNPID"
unset RO_MNT RUNROOTFS SQFUSE BWRAP NOT_TERM FOVERFS \
      MKSQFS NVDRVMNT BWRAP_CAP NVIDIA_DRIVER_BIND EXEC_STATUS \
      SESSION_MANAGER UNSQFS TMP_BIND SYS_HOME UNPIDS_BIND  \
      NETWORK_BIND SET_HOME_DIR SET_CONF_DIR HOME_BIND BWRAP_ARGS \
      LD_CACHE_BIND ADD_LD_CACHE NEW_HOME TMPDIR_BIND EXEC_ARGS \
      FUSE_PIDS XDG_RUN_BIND XORG_CONF_BIND SUID_BWRAP OVERFS_MNT \
      SET_RUNIMAGE_CONFIG SET_RUNIMAGE_INTERNAL_CONFIG OVERFS_DIR \
      RUNRUNTIME RUNSTATIC UNLIM_WAIT SETENV_ARGS SLIRP FORCE_CLEANUP \
      SANDBOX_HOME_DIR MACHINEID_BIND

[[ ! -n "$LANG" || "$LANG" =~ "UTF8" ]] && \
    export LANG=en_US.UTF-8

if [[ -n "$RUNOFFSET" && -n "$ARGV0" ]]
    then
        export RUNSTATIC="$RUNDIR/static"
        export PATH="$SYS_PATH:$RUNSTATIC"
        if [ ! -n "$RUNIMAGE" ] # KDE Neon, CachyOS, Puppy Linux bug
            then
                if [ -x "$(realpath "$ARGV0" 2>/dev/null)" ]
                    then
                        export RUNIMAGE="$(realpath "$ARGV0" 2>/dev/null)"
                elif [ -x "$(realpath "$(which "$ARGV0" 2>/dev/null)" 2>/dev/null)" ]
                    then
                        export RUNIMAGE="$(realpath "$(which "$ARGV0" 2>/dev/null)" 2>/dev/null)"
                else
                    export RUNIMAGE="$ARGV0"
                fi
        fi
        if [ -x "$(realpath -s "$ARGV0" 2>/dev/null)" ]
            then
                RUNSRC="$(realpath -s "$ARGV0" 2>/dev/null)"
        elif [ -x "$(realpath -s "$(which "$ARGV0" 2>/dev/null)" 2>/dev/null)" ]
            then
                RUNSRC="$(realpath -s "$(which "$ARGV0" 2>/dev/null)" 2>/dev/null)"
        else
            RUNSRC="$RUNIMAGE"
        fi
        export RUNIMAGEDIR="$(dirname "$RUNIMAGE" 2>/dev/null)"
        RUNIMAGENAME="$(basename "$RUNIMAGE" 2>/dev/null)"
    else
        [ ! -n "$RUNDIR" ] && \
            export RUNDIR="$(dirname "$(realpath "$0" 2>/dev/null)" 2>/dev/null)"
        export RUNSTATIC="$RUNDIR/static"
        export PATH="$SYS_PATH:$RUNSTATIC"
        export RUNIMAGEDIR="$(realpath "$RUNDIR/../" 2>/dev/null)"
        if [ ! -n "$RUNSRC" ]
            then
                if [ -x "$(realpath -s "$0" 2>/dev/null)" ]
                    then
                        RUNSRC="$(realpath -s "$0" 2>/dev/null)"
                elif [ -x "$(realpath -s "$(which "$0" 2>/dev/null)" 2>/dev/null)" ]
                    then
                        RUNSRC="$(realpath -s "$(which "$0" 2>/dev/null)" 2>/dev/null)"
                else
                    RUNSRC="$RUNDIR/Run"
                fi
        fi
fi

export RUNROOTFS="$RUNDIR/rootfs"
export RUNCACHEDIR="$RUNIMAGEDIR/cache"
export RUNCONFIGDIR="$RUNIMAGEDIR/config"
export RUNOVERFSDIR="$RUNIMAGEDIR/overlayfs"
export RUNRUNTIME="$RUNSTATIC/runtime-fuse2-all"
export SANDBOXHOMEDIR="$RUNIMAGEDIR/sandbox-home"
export PORTABLEHOMEDIR="$RUNIMAGEDIR/portable-home"
export RUNSRCNAME="$(basename "$RUNSRC" 2>/dev/null)"
OVERFSLIST="$(ls -A "$RUNOVERFSDIR" 2>/dev/null)"
export RUNSTATIC_VERSION="$(cat "$RUNSTATIC/.version" 2>/dev/null)"
export RUNROOTFS_VERSION="$(cat "$RUNROOTFS/.version" \
                         "$RUNROOTFS/.type" \
                         "$RUNROOTFS/.build" 2>/dev/null|\
                         sed ':a;/$/N;s/\n/./;ta')"
export RUNROOTFSTYPE="$(cat "$RUNROOTFS/.type" 2>/dev/null)"
export RUNRUNTIME_VERSION="$("$RUNRUNTIME" --runtime-version|& awk '{print$2}')"

[ ! -n "$(tty|grep -v 'not a'|grep -Eo 'tty|pts')" ] && \
    NOT_TERM=1

bash() { "$RUNSTATIC/bash" "$@" ; }

error_msg() {
    echo -e "${RED}[ ERROR ][$(date +"%Y.%m.%d %T")]: $@ $RESETCOLOR"
    if [ "$NOT_TERM" == 1 ]
        then
            notify-send -a 'RunImage Error' "$@" 2>/dev/null &
    fi
}

info_msg() {
    if [ "$QUIET_MODE" != 1 ]
        then
            echo -e "${GREEN}[ INFO ][$(date +"%Y.%m.%d %T")]: $@ $RESETCOLOR"
            if [[ "$NOT_TERM" == 1 && "$DONT_NOTIFY" != 1 ]]
                then
                    notify-send -a 'RunImage Info' "$@" 2>/dev/null &
            fi
    fi
}

warn_msg() {
    if [ "$QUIET_MODE" != 1 ]
        then
            echo -e "${YELLOW}[ WARNING ][$(date +"%Y.%m.%d %T")]: $@ $RESETCOLOR"
            if [[ "$NOT_TERM" == 1 && "$DONT_NOTIFY" != 1 ]]
                then
                    notify-send -a 'RunImage Warning' "$@" 2>/dev/null &
            fi
    fi
}

console_info_notify() {
    if [ "$NOT_TERM" == 1 ]
        then
            notify-send -a "RunImage Info" "See the information in the console!" &
        else
            return 1
    fi
}

mount_exist() {
    time_out=1000 # =~ 3 sec
    wait_time=0
    while true
        do
            if [ "$wait_time" -le "$time_out" ]
                then
                    if [[ -d "/proc/$1" && -n "$(ls -A "$2" 2>/dev/null)" ]]
                        then
                            return 0
                        else
                            wait_time="$(( $wait_time + 1 ))"
                            sleep 0.0001
                    fi
                else
                    return 1
            fi
    done
}

is_sys_exe() {
    if [[ -x "$(which -a "$1" 2>/dev/null|grep -v "$RUNSTATIC"|head -1)" ]]
        then
            return 0
        else
            return 1
    fi
}

which_sys_exe() { which -a "$1" 2>/dev/null|grep -v "$RUNSTATIC"|head -1 ; }

try_dl() {
    [ -n "$2" ] && \
      FILEDIR="$2"||\
      FILEDIR="."
    FILENAME="$(basename "$1")"
    if which aria2c &>/dev/null
        then
            aria2c -x 13 -s 13 --allow-overwrite -d "$FILEDIR" "$1"
    elif which wget &>/dev/null
        then
            wget -q --show-progress --no-check-certificate --content-disposition \
                -t 3 -T 5 -w 0.5 "$1" -O "$FILEDIR/$FILENAME"
    elif which curl &>/dev/null
        then
            curl --insecure --fail -L "$1" -o "$FILEDIR/$FILENAME"
    else
        error_msg "Downloader not found!"
        return 1
    fi
    return $?
}

get_nvidia_driver_image() {
    (if [[ -n "$1" || -n "$nvidia_version" ]]
        then
            [ ! -n "$nvidia_version" ] && \
                nvidia_version="$1"
            [[ -d "$2" && ! -n "$nvidia_drivers_dir" ]] && \
                nvidia_drivers_dir="$2"
            [[ ! -d "$2" && ! -n "$nvidia_drivers_dir" ]] && \
                nvidia_drivers_dir="."
            [ ! -n "$nvidia_driver_image" ] && \
                nvidia_driver_image="$nvidia_version.nv.drv"
            try_mkdir "$nvidia_drivers_dir"
            info_msg "Downloading Nvidia ${nvidia_version} driver, please wait..."
            nvidia_driver_run="NVIDIA-Linux-x86_64-${nvidia_version}.run"
            driver_url_list=("https://github.com/VHSgunzo/runimage-nvidia-drivers/releases/download/v${nvidia_version}/$nvidia_driver_image" \
                             "https://us.download.nvidia.com/XFree86/Linux-x86_64/${nvidia_version}/$nvidia_driver_run")
            if try_dl "${driver_url_list[0]}" "$nvidia_drivers_dir"
                then
                    return 0
            elif try_dl "${driver_url_list[1]}" "$nvidia_drivers_dir"
                then
                    trash_libs="libEGL.so.1.1.0 libGLdispatch.so.0 \
                        libGLESv1_CM.so.1.2.0 libGLESv2.so.2.1.0 libGL.so.1.7.0 \
                        libGLX.so.0 libOpenCL.so.1.0.0 libOpenGL.so.0 \
                        libnvidia-opencl* libnvidia-compiler* libcudadebugger*"
                    chmod u+x "$nvidia_drivers_dir/$nvidia_driver_run"
                    info_msg "Unpacking $nvidia_driver_run..."
                    (cd "$nvidia_drivers_dir" && \
                        "./$nvidia_driver_run" -x &>/dev/null
                        rm -f "$nvidia_driver_run"
                        mv -f "NVIDIA-Linux-x86_64-${nvidia_version}" "$nvidia_version")
                    info_msg "Creating a driver directory structure..."
                    (cd "$nvidia_drivers_dir/$nvidia_version" && \
                        rm -rf html kernel* libglvnd_install_checker 32/libglvnd_install_checker \
                            supported-gpus systemd *.gz *.bz2 *.txt *Changelog LICENSE \
                            .manifest *.desktop *.png firmware 2>/dev/null
                        try_mkdir profiles && mv *application-profiles* profiles
                        try_mkdir wine && mv *nvngx.dll wine
                        try_mkdir json && mv *.json json
                        try_mkdir conf && mv *.conf *.icd conf
                        for lib in $trash_libs ; do rm $lib 32/$lib 2>/dev/null ; done
                        try_mkdir bin && mv *.sh mkprecompiled nvidia-cuda-mps-control nvidia-cuda-mps-server \
                            nvidia-debugdump nvidia-installer nvidia-modprobe nvidia-ngx-updater \
                            nvidia-persistenced nvidia-powerd nvidia-settings nvidia-smi nvidia-xconfig bin
                        try_mkdir 64 && mv *.so* 64)
                    info_msg "Creating a squashfs driver image..."
                    info_msg "$nvidia_drivers_dir/$nvidia_driver_image"
                    echo -en "$BLUE"
                    if "$MKSQFS" "$nvidia_drivers_dir/$nvidia_version" "$nvidia_drivers_dir/$nvidia_driver_image" \
                        -root-owned -no-xattrs -noappend -b 1M -comp zstd -Xcompression-level 19 -quiet
                        then
                            info_msg "Deleting the source directory of the driver..."
                            rm -rf "$nvidia_drivers_dir/$nvidia_version"
                            return 0
                        else
                            return 1
                    fi
                    echo -en "$RESETCOLOR"
                else
                    error_msg "Failed to download nvidia driver!"
                    [ -f "$nvidia_drivers_dir/$nvidia_driver_image" ] && \
                        rm -f "$nvidia_drivers_dir/$nvidia_driver_image"* 2>/dev/null
                    [ -f "$nvidia_drivers_dir/$nvidia_driver_run" ] && \
                        rm -f "$nvidia_drivers_dir/$nvidia_driver_run"* 2>/dev/null
                    return 1
            fi
        else
            error_msg "You must specify the nvidia driver version!"
            return 1
    fi)
}

mount_nvidia_driver_image() {
    if [[ -n "$1" && -n "$(echo "$1"|grep -o "\.nv\.drv$")" ]]
        then
            [ ! -n "$nvidia_version" ] && \
                nvidia_version="$(echo "$1"|sed 's|.nv.drv||g')"
            [ ! -n "$NVDRVMNT" ] && \
                NVDRVMNT="/tmp/.mount_nv${nvidia_version}drv.$RUNPID"
            info_msg "Mounting the nvidia driver image: $(basename "$1")"
            try_mkdir "$NVDRVMNT"
            "$SQFUSE" -f "$1" "$NVDRVMNT" -o ro &
            FUSE_PID="$!"
            export FUSE_PIDS="$FUSE_PID $FUSE_PIDS"
            if mount_exist "$FUSE_PID" "$NVDRVMNT"
                then
                    nvidia_driver_dir="$NVDRVMNT"
                else
                    error_msg "Failed to mount the nvidia driver image!"
                    rm -f "$1" 2>/dev/null
                    return 1
            fi
        else
            error_msg "You must specify the nvidia driver image!"
            return 1
    fi
}

check_nvidia_driver() {
    unset NVIDIA_DRIVER_BIND
    print_nv_drv_dir() { info_msg "Found nvidia driver directory: $(basename "$nvidia_driver_dir")" ; }
    update_ld_cache() {
        if [ "$(cat "$RUNCACHEDIR/ld.so.version" 2>/dev/null)" != "$RUNROOTFS_VERSION-$nvidia_version" ]
            then
                info_msg "Updating the nvidia library cache..."
                if (NO_BWRAP_WAIT=1 SANDBOX_NET=0 bwrun /usr/bin/ldconfig -C "/tmp/ld.so.cache" 2>/dev/null)
                    then
                        try_mkdir "$RUNCACHEDIR"
                        if mv -f "/tmp/ld.so.cache" \
                            "$RUNCACHEDIR/ld.so.cache" 2>/dev/null
                            then
                                echo "$RUNROOTFS_VERSION-$nvidia_version" > \
                                    "$RUNCACHEDIR/ld.so.version"
                                if [ "$1" == 'cp' ]
                                    then
                                        cp -f "$RUNCACHEDIR/ld.so.cache" \
                                            "$RUNROOTFS/etc/ld.so.cache" 2>/dev/null
                                        echo "$RUNROOTFS_VERSION-$nvidia_version" > \
                                            "$RUNROOTFS/etc/ld.so.version"
                                    else
                                        ADD_LD_CACHE=1
                                fi
                            else
                                error_msg "Failed to merge nvidia library cache!"
                                return 1
                        fi
                    else
                        error_msg "Failed to update nvidia library cache!"
                        return 1
                fi
            else
                if [ "$1" == 'cp' ]
                    then
                        if [ "$(cat "$RUNROOTFS/etc/ld.so.version" 2>/dev/null)" != "$RUNROOTFS_VERSION-$nvidia_version" ]
                            then
                                cp -f "$RUNCACHEDIR/ld.so.cache" \
                                    "$RUNROOTFS/etc/ld.so.cache" 2>/dev/null
                                echo "$RUNROOTFS_VERSION-$nvidia_version" > \
                                            "$RUNROOTFS/etc/ld.so.version"
                        fi
                    else
                        ADD_LD_CACHE=1
                fi
        fi
    }
    if lsmod|grep nvidia &>/dev/null || nvidia-smi &>/dev/null
        then
            unset nvidia_driver_dir
            nvidia_drivers_dir="$RUNIMAGEDIR/nvidia-drivers"
            if modinfo nvidia &>/dev/null
                then
                    nvidia_version="$(modinfo -F version nvidia 2>/dev/null)"
            elif nvidia-smi &>/dev/null
                then
                    nvidia_version="$(nvidia-smi --query-gpu=driver_version --format=csv,noheader|head -1)"
            else
                if [ -d /usr/lib/x86_64-linux-gnu ]
                    then
                        nvidia_version="$(basename /usr/lib/x86_64-linux-gnu/libGLX_nvidia.so.*.*|tail -c +18)"
                    else
                        nvidia_version="$(basename /usr/lib/libGLX_nvidia.so.*.*|tail -c +18)"
                fi
            fi
            if [[ -n "$nvidia_version" && "$nvidia_version" != "*.*" ]]
                then
                    nvidia_version_inside="$(basename "$RUNROOTFS/usr/lib/libGLX_nvidia.so".*.*|tail -c +18)"
                    if [ "$nvidia_version" != "$nvidia_version_inside" ]
                        then
                            if [[ -n "$nvidia_version_inside" && "$nvidia_version_inside" != "*.*" ]]
                                then
                                    nvidia_driver_image="$nvidia_version.nv.drv"
                                    NVDRVMNT="/tmp/.mount_nv${nvidia_version}drv.$RUNPID"
                                    [ "$nvidia_version_inside" != "000.00.00" ] && \
                                        warn_msg "Nvidia driver version mismatch detected, trying to fix it"
                                    if [ ! -f "$nvidia_drivers_dir/$nvidia_version/64/nvidia_drv.so" ] && \
                                        [ ! -f "$RUNIMAGEDIR/$nvidia_driver_image" ] && \
                                        [ ! -f "$nvidia_drivers_dir/$nvidia_driver_image" ] && \
                                        [ ! -f "$NVDRVMNT/64/nvidia_drv.so" ] && \
                                        [ ! -f "$RUNDIR/nvidia-drivers/$nvidia_version/64/nvidia_drv.so" ] && \
                                        [ ! -f "$RUNDIR/nvidia-drivers/$nvidia_driver_image" ]
                                        then
                                            if get_nvidia_driver_image
                                                then
                                                    mount_nvidia_driver_image "$nvidia_drivers_dir/$nvidia_driver_image"
                                                else
                                                    nvidia_driver_dir="$nvidia_drivers_dir/$nvidia_version"
                                            fi
                                        else
                                            if [ -f "$NVDRVMNT/64/nvidia_drv.so" ]
                                                then
                                                    nvidia_driver_dir="$NVDRVMNT"
                                                    print_nv_drv_dir
                                            elif [ -f "$nvidia_drivers_dir/$nvidia_version/64/nvidia_drv.so" ]
                                                then
                                                    nvidia_driver_dir="$nvidia_drivers_dir/$nvidia_version"
                                                    print_nv_drv_dir
                                            elif [ -f "$RUNIMAGEDIR/$nvidia_driver_image" ]
                                                then
                                                    mount_nvidia_driver_image "$RUNIMAGEDIR/$nvidia_driver_image"
                                            elif [ -f "$nvidia_drivers_dir/$nvidia_driver_image" ]
                                                then
                                                    mount_nvidia_driver_image "$nvidia_drivers_dir/$nvidia_driver_image"
                                            elif [ -f "$RUNDIR/nvidia-drivers/$nvidia_version/64/nvidia_drv.so" ]
                                                then
                                                    nvidia_driver_dir="$RUNDIR/nvidia-drivers/$nvidia_version"
                                                    print_nv_drv_dir
                                            elif [ -f "$RUNDIR/nvidia-drivers/$nvidia_driver_image" ]
                                                then
                                                    mount_nvidia_driver_image "$RUNDIR/nvidia-drivers/$nvidia_driver_image"
                                            fi
                                    fi
                                else
                                    error_msg "No nvidia driver found in RunImage!"
                                    return 1
                            fi
                            if [ -f "$nvidia_driver_dir/64/nvidia_drv.so" ]
                                then
                                    nvidia_libs_list="libcuda.so libEGL_nvidia.so libGLESv1_CM_nvidia.so \
                                        libGLESv2_nvidia.so libGLX_nvidia.so libnvcuvid.so libnvidia-allocator.so \
                                        libnvidia-cfg.so libnvidia-eglcore.so libnvidia-encode.so libnvidia-fbc.so \
                                        libnvidia-glcore.so libnvidia-glsi.so libnvidia-glvkspirv.so libnvidia-ml.so \
                                        libnvidia-ngx.so libnvidia-opticalflow.so libnvidia-ptxjitcompiler.so \
                                        libnvidia-rtcore.so libnvidia-tls.so libnvidia-vulkan-producer.so libnvoptix.so \
                                        libnvidia-nvvm.so"
                                    for lib in ${nvidia_libs_list}
                                        do
                                            if [ -f "$RUNROOTFS/usr/lib/${lib}.${nvidia_version_inside}" ]
                                                then
                                                    NVIDIA_DRIVER_BIND+=("--ro-bind-try" \
                                                        "$nvidia_driver_dir/64/${lib}.${nvidia_version}" \
                                                        "/usr/lib/${lib}.${nvidia_version_inside}")
                                            fi
                                            if [ -f "$RUNROOTFS/usr/lib32/${lib}.${nvidia_version_inside}" ]
                                                then
                                                    NVIDIA_DRIVER_BIND+=("--ro-bind-try" \
                                                        "$nvidia_driver_dir/32/${lib}.${nvidia_version}" \
                                                        "/usr/lib32/${lib}.${nvidia_version_inside}")
                                            fi
                                    done
                                    if [ -f "$RUNROOTFS/usr/lib/libnvidia-egl-gbm.so.1.1.0" ]
                                        then
                                            NVIDIA_DRIVER_BIND+=("--ro-bind-try" \
                                                "$nvidia_driver_dir/64/libnvidia-egl-gbm.so.1.1.0" \
                                                "/usr/lib/libnvidia-egl-gbm.so.1.1.0")
                                    fi
                                    if [ -f "$RUNROOTFS/usr/lib/nvidia/xorg/libglxserver_nvidia.so.${nvidia_version_inside}" ]
                                        then
                                            NVIDIA_DRIVER_BIND+=("--ro-bind-try" \
                                                "$nvidia_driver_dir/64/libglxserver_nvidia.so.${nvidia_version}" \
                                                "/usr/lib/nvidia/xorg/libglxserver_nvidia.so.${nvidia_version_inside}")
                                    fi
                                    if [ -f "$RUNROOTFS/usr/lib/vdpau/libvdpau_nvidia.so.${nvidia_version_inside}" ]
                                        then
                                            NVIDIA_DRIVER_BIND+=("--ro-bind-try" \
                                                "$nvidia_driver_dir/64/libvdpau_nvidia.so.${nvidia_version}" \
                                                "/usr/lib/vdpau/libvdpau_nvidia.so.${nvidia_version_inside}")
                                    fi
                                    if [ -f "$RUNROOTFS/usr/lib32/vdpau/libvdpau_nvidia.so.${nvidia_version_inside}" ]
                                        then
                                            NVIDIA_DRIVER_BIND+=("--ro-bind-try" \
                                                "$nvidia_driver_dir/32/libvdpau_nvidia.so.${nvidia_version}" \
                                                "/usr/lib32/vdpau/libvdpau_nvidia.so.${nvidia_version_inside}")
                                    fi
                                    if [ -f "$RUNROOTFS/usr/lib/xorg/modules/drivers/nvidia_drv.so" ]
                                        then
                                            NVIDIA_DRIVER_BIND+=("--ro-bind-try" \
                                                "$nvidia_driver_dir/64/nvidia_drv.so" \
                                                "/usr/lib/xorg/modules/drivers/nvidia_drv.so")
                                    fi
                                    if [ -f "$RUNROOTFS/usr/share/egl/egl_external_platform.d/15_nvidia_gbm.json" ]
                                        then
                                            NVIDIA_DRIVER_BIND+=("--ro-bind-try" \
                                                "$nvidia_driver_dir/json/15_nvidia_gbm.json" \
                                                "/usr/share/egl/egl_external_platform.d/15_nvidia_gbm.json")
                                    fi
                                    if [ -f "$RUNROOTFS/usr/share/glvnd/egl_vendor.d/10_nvidia.json" ]
                                        then
                                            NVIDIA_DRIVER_BIND+=("--ro-bind-try" \
                                                "$nvidia_driver_dir/json/10_nvidia.json" \
                                                "/usr/share/glvnd/egl_vendor.d/10_nvidia.json")
                                    fi
                                    if [ -f "$RUNROOTFS/usr/share/vulkan/icd.d/nvidia_icd.json" ]
                                        then
                                            NVIDIA_DRIVER_BIND+=("--ro-bind-try" \
                                                "$nvidia_driver_dir/json/nvidia_icd.json" \
                                                "/usr/share/vulkan/icd.d/nvidia_icd.json")
                                    fi
                                    if [ -f "$RUNROOTFS/usr/share/vulkan/implicit_layer.d/nvidia_layers.json" ]
                                        then
                                            NVIDIA_DRIVER_BIND+=("--ro-bind-try" \
                                                "$nvidia_driver_dir/json/nvidia_layers.json" \
                                                "/usr/share/vulkan/implicit_layer.d/nvidia_layers.json")
                                    fi
                                    if [ -f "$RUNROOTFS/usr/share/dbus-1/system.d/nvidia-dbus.conf" ]
                                        then
                                            NVIDIA_DRIVER_BIND+=("--ro-bind-try" \
                                                "$nvidia_driver_dir/conf/nvidia-dbus.conf" \
                                                "/usr/share/dbus-1/system.d/nvidia-dbus.conf")
                                    fi
                                    if [ -d "$RUNROOTFS/usr/share/nvidia" ]
                                        then
                                            NVIDIA_DRIVER_BIND+=("--ro-bind-try" \
                                                "$nvidia_driver_dir/profiles" \
                                                "/usr/share/nvidia")
                                    fi
                                    if [ -d "$RUNROOTFS/usr/lib/nvidia/wine" ]
                                        then
                                            NVIDIA_DRIVER_BIND+=("--ro-bind-try" \
                                                "$nvidia_driver_dir/wine" \
                                                "/usr/lib/nvidia/wine")
                                    fi
                                    if [ -d "$RUNROOTFS/usr/bin/nvidia" ] && \
                                        [ -d "$RUNROOTFS/usr/lib/nvidia/64" ] && \
                                        [ -d "$RUNROOTFS/usr/lib/nvidia/32" ]
                                        then
                                            NVIDIA_DRIVER_BIND+=("--ro-bind-try" "$nvidia_driver_dir/bin" "/usr/bin/nvidia" \
                                                "--ro-bind-try" "$nvidia_driver_dir/64" "/usr/lib/nvidia/64" \
                                                "--ro-bind-try" "$nvidia_driver_dir/32" "/usr/lib/nvidia/32")
                                            add_bin_pth '/usr/bin/nvidia'
                                            add_lib_pth '/usr/lib/nvidia/64:/usr/lib/nvidia/32'
                                    fi
                                    if [[ -n "$RUNIMAGE" && "$OVERFS_MODE" != 1 && \
                                        "$KEEP_OVERFS" != 1 && ! -n "$OVERFS_ID" ]]
                                        then
                                            update_ld_cache
                                        else
                                            update_ld_cache cp
                                    fi
                                else
                                    error_msg "Nvidia driver not found!"
                                    return 1
                            fi
                    fi
            fi
    fi
}

add_lib_pth() {
    if [ -n "$LIB_PATH" ]
        then
            if [ ! -n "$(echo "$LIB_PATH"|grep -ow "$1" 2>/dev/null)" ]
                then
                    LIB_PATH="${1}:${LIB_PATH}"
            fi
        else
            LIB_PATH="${1}"
    fi
}

add_bin_pth() {
    if [ -n "$BIN_PATH" ]
        then
            if [ ! -n "$(echo "$BIN_PATH"|grep -ow "$1" 2>/dev/null)" ]
                then
                    BIN_PATH="${1}:${BIN_PATH}"
            fi
        else
            BIN_PATH="${1}"
    fi
}

try_unmount() {
    if [[ -n "$1" && -n "$(grep -o "$1" /proc/self/mounts 2>/dev/null)" ]]
        then
            unset DORM
            if fusermount -uz "$1" 2>/dev/null
                then DORM=1
            elif umount -l "$1" 2>/dev/null
                then DORM=1
            elif [ "$ALLOW_BG" != 1 ] && \
                kill $FUSE_PIDS 2>/dev/null
                then DORM=1
            else
                error_msg "Failed to unmount: '$1'"
                return 1
            fi
            [[ -d "$1" && "$DORM" == 1 ]] && \
                rm -rf "$1" 2>/dev/null
            return 0
    fi
}

try_mkdir() {
    if [ ! -d "$1" ]
        then
            if ! mkdir -p "$1"
                then
                    error_msg "Failed to create directory: '$1'"
                    FORCE_CLEANUP=1 cleanup
                    exit 1
            fi
    fi
}

run_attach() {
    ns_attach() {
        target="$(ps -o pid=,cmd= -p $(cat "/tmp/.rpids.$1" 2>/dev/null) 2>/dev/null|\
                  grep -v "/tmp/\.mount.*/static/"|grep -v "$RUNDIR/static/"|\
                  grep -v "RunDir.*/static/"|grep -v "squashfuse.*$RUNIMAGEDIR.*offset="|\
                  grep -v "\.nv\.drv /tmp/\.mount_nv.*drv\."|grep -v "fuse-overlayfs .*/cache/overlayfs/"|\
                  grep -v "bwrap .*/cache/overlayfs/"|grep -v "bwrap .*/tmp/\.mount.*"|head -1|awk '{print$1}')"
        if [ -n "$target" ]
            then
                info_msg "Attaching to RunImage RUNPID: $1"
                (while [[ -d "/proc/$target" && -d "/proc/$RUNPID" ]]; do sleep 0.5; done
                FORCE_CLEANUP=1 cleanup) &
                shift
                for args in "-n -p" "-n" "-p" " "
                    do
                        if nsenter --preserve-credentials -U -m $args \
                            -t $target /usr/bin/true &>/dev/null
                            then
                                importenv $target nsenter --preserve-credentials \
                                    --wd=/proc/$target/cwd -U -m $args -t $target "$@"
                                return $?
                        fi
                done
        fi
        error_msg "Failed to attach to RunImage container!"
        return 1
    }
    if [[ "$1" =~ ^[0-9]+$ ]]
        then
            if [ -f "/tmp/.rpids.$1" ]
                then
                    if [ -n "$2" ]
                        then
                            ns_attach "$@"
                        else
                            ns_attach "$@" "${RUN_SHELL[@]}"
                    fi
                else
                    error_msg "RunImage container not found by RUNPID: $1"
                    return 1
            fi
        else
            rpids_num="$(ls -1 /tmp/.rpids.* 2>/dev/null|wc -l)"
            if [ "$rpids_num" == 0 ]
                then
                    error_msg "No running RunImage containers found!"
                    return 1
            elif [ "$rpids_num" == 1 ]
                then
                    runpid="$(ls -1 /tmp/.rpids.* 2>/dev/null|head -1|cut -d'.' -f3)"
                    if [ -n "$1" ]
                        then
                            ns_attach "$runpid" "$@"
                        else
                            ns_attach "$runpid" "${RUN_SHELL[@]}"
                    fi
            else
                error_msg "Specify the RunImage RUNPID!"
                info_msg "Available RUNPIDs: $(echo $(ls -1 /tmp/.rpids.* 2>/dev/null|cut -d'.' -f3))"
                return 1
            fi
    fi
}

force_kill() {
    unset SUCCKILL MOUNTPOINTS SUCCUMNT
    MOUNTPOINTS="$(grep -E "$([ -n "$RUNIMAGENAME" ] && \
                   echo "$RUNIMAGENAME"||echo "$RUNIMAGEDIR")|/tmp/.mount_nv.*drv|fuse-overlayfs.*$RUNIMAGEDIR" \
                    /proc/self/mounts|grep -v "$RUNDIR"|awk '{print$2}')"
    if [ -n "$MOUNTPOINTS" ]
        then
            (IFS=$'\n' ; for umnt in $MOUNTPOINTS
                do
                    try_unmount "$umnt"
            done) && SUCCUMNT=1
    fi
    try_kill "$(cat /tmp/.rpids.* 2>/dev/null)" && \
        SUCCKILL=1
    [[ "$SUCCKILL" == 1 || "$SUCCUMNT" == 1 ]] && \
        info_msg "RunImage successfully killed!"
}

wait_pid() {
    if [ -n "$1" ]
        then
            if [ "$UNLIM_WAIT" == 1 ]
                then
                    while [ -d "/proc/$1" ]; do sleep 0.1; done
                else
                    [ -n "$2" ] && \
                        timeout="$2"||
                        timeout="100"
                    waittime=1
                    while [[ -d "/proc/$1" && "$waittime" -le "$timeout" ]]
                        do
                            sleep 0.01
                            waittime="$(( $waittime + 1 ))"
                    done
            fi
    fi
}

try_kill() {
    ret=1
    if [ -n "$1" ]
        then
            for pid in $1
                do
                    trykillnum=1
                    while [[ -n "$pid" && -d "/proc/$pid" ]]
                        do
                            if [[ "$trykillnum" -le 3 ]]
                                then
                                    kill -2 $pid 2>/dev/null
                                    ret=$?
                                    sleep 0.05
                                else
                                    kill -9 $pid 2>/dev/null
                                    ret=$?
                                    wait $pid &>/dev/null
                                    wait_pid "$pid"
                            fi
                            trykillnum="$(( $trykillnum + 1 ))"
                    done
            done
    fi
    return $ret
}

cleanup() {
    if [[ "$NO_CLEANUP" != 1 || "$FORCE_CLEANUP" == 1 ]]
        then
            [ "$FORCE_CLEANUP" == 1 ] && \
                ALLOW_BG=0 && QUIET_MODE=1
            if [ -n "$FUSE_PIDS" ]
                then
                    try_unmount "$RO_MNT"
                    try_unmount "$NVDRVMNT"
                    [[ "$KEEP_OVERFS" != 1 && "$ALLOW_BG" != 1 ]] && \
                        try_unmount "$OVERFS_MNT"
            fi
            if [ "$ALLOW_BG" != 1 ]
                then
                    [ -n "$FUSE_PIDS" ] && \
                        kill $FUSE_PIDS 2>/dev/null
                    if [ -n "$DBUSD_PID" ]
                        then
                            kill $DBUSD_PID 2>/dev/null
                            DBUSD_SOCKET="${DBUSD_ADDRSS#unix:path=}"
                            [ -S "$DBUSD_SOCKET" ] && \
                                rm -f "$DBUSD_SOCKET" 2>/dev/null
                    fi
                    try_kill "$(cat "$RPIDSFL" 2>/dev/null|grep -v "$RUNPID")"
                    [ -f "$RPIDSFL" ] && \
                        rm -f "$RPIDSFL" 2>/dev/null
            fi
            if [[ -d "$OVERFS_DIR" && "$KEEP_OVERFS" != 1 && "$ALLOW_BG" != 1 ]]
                then
                    info_msg "Removing OverlayFS..."
                    rm -rf "$OVERFS_DIR" 2>/dev/null
            fi
        else
            warn_msg "Cleanup is disabled!"
    fi
}

get_child_pids() {
    _child_pids="$(ps --forest -o pid= -g $(ps -o sid= -p $1 2>/dev/null) 2>/dev/null)"
    echo -e "$1\n$(ps -o pid=,cmd= -p $_child_pids 2>/dev/null|sort -n|sed "0,/$1/d"|\
    grep -v "bash $RUNDIR/Run.sh"|grep -Pv '\d+ sleep \d+'|grep -wv "$RUNPPID"|\
    awk '{print$1}')"|sort -nu
}

bwrun() {
    unset WAITBWPID
    if [ "$NO_NVIDIA_CHECK" == 1 ]
        then
            warn_msg "Nvidia driver check is disabled!"
    elif [[ "$NO_NVIDIA_CHECK" != 1 && ! -n "$NVIDIA_DRIVER_BIND" ]]
        then
            check_nvidia_driver
    fi
    [ "$ADD_LD_CACHE" == 1 ] && \
        LD_CACHE_BIND=("--bind-try" \
                    "$RUNCACHEDIR/ld.so.cache" "/etc/ld.so.cache") || \
        unset LD_CACHE_BIND
    if [[ "$SANDBOX_NET" == 1 && "$NO_NET" != 1 ]]
        then
            (while [[ -d "/proc/$RUNPID" && ! -f "$BWINFFL" ]]; do sleep 0.01; done
            info_msg "Creating a network sandbox..."
            "$SLIRP" --configure --disable-host-loopback \
                $([ -n "$SANDBOX_NET_CIDR" ] && echo "--cidr=$SANDBOX_NET_CIDR") \
                $([ -n "$SANDBOX_NET_MTU" ] && echo "--mtu=$SANDBOX_NET_MTU") \
                $([ -n "$SANDBOX_NET_MAC" ] && echo "--macaddress=$SANDBOX_NET_MAC") \
                "$(grep 'child-pid' "$BWINFFL" 2>/dev/null|grep -Po '\d+')" \
                $([ -n "$SANDBOX_NET_TAPNAME" ] && echo "$SANDBOX_NET_TAPNAME"||echo 'eth0') &
            SLIRP_PID=$!
            sleep 0.1
            if [[ -n "$SLIRP_PID" && -d "/proc/$SLIRP_PID" ]]
                then
                    while [[ -d "/proc/$RUNPID" && -f "$BWINFFL" ]]; do sleep 0.01; done
                    try_kill "$SLIRP_PID"
                else
                    error_msg "Failed to create a network sandbox!"
                    sleep 1
                    FORCE_CLEANUP=1 cleanup
                    exit 1
            fi) &
    fi
    if [ "$NO_BWRAP_WAIT" != 1 ]
        then
            (wait_bwrap=100
            while [[ "$wait_bwrap" -gt 0 && ! -f "$BWINFFL" ]]
                do
                    wait_bwrap="$(( $wait_bwrap - 1 ))"
                    sleep 0.01
            done; sleep 1) &
            WAITBWPID=$!
    fi
    "$BWRAP" --bind-try "$RUNROOTFS" / \
        --info-fd 8 \
        --proc /proc \
        --tmpfs /var/log \
        --die-with-parent \
        --bind-try /sys /sys \
        --bind-try /mnt /mnt \
        --bind-try /srv /srv \
        --bind-try /boot /boot \
        --dev-bind-try /dev /dev \
        --bind-try /media /media \
        --bind-try /var/tmp /var/tmp \
        --bind-try /var/mnt /var/mnt \
        --bind-try /var/opt /var/opt \
        --bind-try /var/home /var/home \
        --bind-try /var/empty /var/empty \
        --bind-try /var/spool /var/spool \
        --bind-try /var/local /var/local \
        --bind-try /var/games /var/games \
        --ro-bind-try /etc/group /etc/group \
        --bind-try /lib/modules /lib/modules \
        --ro-bind-try /etc/passwd /etc/passwd \
        --bind-try /var/roothome /var/roothome \
        --bind-try /var/log/wtmp /var/log/wtmp \
        --ro-bind-try /etc/hostname /etc/hostname \
        --ro-bind-try /etc/localtime /etc/localtime \
        --bind-try /var/log/lastlog /var/log/lastlog \
        --ro-bind-try /etc/nsswitch.conf /etc/nsswitch.conf \
        "${MACHINEID_BIND[@]}" \
        "${NVIDIA_DRIVER_BIND[@]}" "${TMP_BIND[@]}" \
        "${NETWORK_BIND[@]}" "${XDG_RUN_BIND[@]}" \
        "${LD_CACHE_BIND[@]}" "${TMPDIR_BIND[@]}" \
        "${UNPIDS_BIND[@]}" "${HOME_BIND[@]}" \
        "${XORG_CONF_BIND[@]}" "${BWRAP_CAP[@]}" \
        --setenv RUNPID "$RUNPID" \
        --setenv NO_AT_BRIDGE "1" \
        --setenv PATH "$BIN_PATH" \
        --setenv GDK_BACKEND "x11" \
        --setenv LD_LIBRARY_PATH "$LIB_PATH" \
        --setenv XDG_CONFIG_DIRS "/etc/xdg:$XDG_CONFIG_DIRS" \
        --setenv XDG_DATA_DIRS "/usr/local/share:/usr/share:$XDG_DATA_DIRS" \
        "${SETENV_ARGS[@]}" "${BWRAP_ARGS[@]}" \
        "${EXEC_ARGS[@]}" \
        "$@" 8>$BWINFFL
    EXEC_STATUS=$?
    [ -n "$WAITBWPID" ] && \
        wait "$WAITBWPID"
    [ -f "$BWINFFL" ] && \
        rm -f "$BWINFFL" 2>/dev/null
    return $EXEC_STATUS
}

overlayfs_list() {
    if [ -n "$OVERFSLIST" ]
        then
            echo -e "${GREEN}OverlayFS:\t${BLUE}SIZE\tPATH\tID"
            for overfs_id in $OVERFSLIST
                do
                    LSTOVERFS_DIR="$RUNOVERFSDIR/$overfs_id"
                    echo -e "${BLUE}$(du --exclude="$LSTOVERFS_DIR/mnt" \
                        -sh "$LSTOVERFS_DIR")\t${overfs_id}${RESETCOLOR}"
            done
        else
            error_msg "OverlayFS not found!"
            return 1
    fi
}

overlayfs_rm() {
    if [[ -n "$OVERFSLIST" || "$1" == 'all' ]]
        then
            if [[ -n "$1" || -n "$OVERFS_ID" ]]
                then
                    overfsrm() {
                        info_msg "Removing OverlayFS: $overfs_id"
                        if [ "$1" == 'force' ]
                            then
                                try_kill "$(lsof -n "$RMOVERFS_MNT"|sed 1d|awk '{print$2}'|sort -u)"
                                try_unmount "$RMOVERFS_MNT"
                        fi
                        rm -rf "$RMOVERFS_DIR"
                        [ ! -d "$RMOVERFS_DIR" ] && \
                            info_msg "Removing completed!"
                    }
                    for overfs_id in $([ "$1" == 'all' ] && echo "$OVERFSLIST"||echo "$@ $OVERFS_ID")
                        do
                            RMOVERFS_DIR="$RUNOVERFSDIR/$overfs_id"
                            if [ -d "$RMOVERFS_DIR" ]
                                then
                                    RMOVERFS_MNT="$RMOVERFS_DIR/mnt"
                                    if [ -n "$(ls -A "$RMOVERFS_MNT" 2>/dev/null)" ]
                                        then
                                            warn_msg "Maybe OverlayFS is currently in use: $overfs_id"
                                            while true
                                                do
                                                    read -p "$(echo -e "\t${RED}Are you sure you want to delete it? ${GREEN}(y/n) ${BLUE}> $RESETCOLOR")" yn
                                                    case $yn in
                                                        [Yy] ) overfsrm force
                                                               break ;;
                                                        [Nn] ) break ;;
                                                    esac
                                            done
                                        else
                                            overfsrm
                                    fi
                                    unset RMOVERFS_MNT
                                else
                                    error_msg "Not found OverlayFS: $overfs_id"
                            fi
                            unset RMOVERFS_DIR
                    done
                else
                    error_msg "Specify the OverlayFS ID!"
                    return 1
            fi
        else
            error_msg "OverlayFS not found!"
            return 1
    fi
}

get_dbus_session_bus_address() {
    set -o pipefail
    unset MACHINE_ID
    if [ -f "/var/lib/dbus/machine-id" ]
        then local MACHINE_ID="$(cat /var/lib/dbus/machine-id 2>/dev/null)"
    elif [ -f "/etc/machine-id" ]
        then local MACHINE_ID="$(cat /etc/machine-id 2>/dev/null)"
    fi
    dbus-launch --autolaunch "$MACHINE_ID" 2>/dev/null|sed 's|,guid=.*$||g'
    return $?
}

try_mkhome() {
    try_mkdir "$1"
    try_mkdir "$1/.cache"
    try_mkdir "$1/.config"
}

pkg_list() { NO_NVIDIA_CHECK=1 QUIET_MODE=1 bwrun /usr/bin/pacman -Q 2>/dev/null ; }

bwrap_help() { NO_NVIDIA_CHECK=1 QUIET_MODE=1 bwrun --help ; }

bin_list() { NO_NVIDIA_CHECK=1 QUIET_MODE=1 bwrun /usr/bin/find /usr/bin/ -executable \
             -type f -maxdepth 1 2>/dev/null|sed 's|/usr/bin/||g' ; }

print_version() {
    info_msg "RunImage version: ${RED}$RUNIMAGE_VERSION"
    info_msg "RootFS version: ${RED}$RUNROOTFS_VERSION"
    info_msg "Static version: ${RED}$RUNSTATIC_VERSION"
    [ -n "$RUNRUNTIME_VERSION" ] && \
        info_msg "RunImage runtime version: ${RED}$RUNRUNTIME_VERSION"
}

run_update() {
    unset PACARG
    info_msg "RunImage update"
    if [ "$FORCE_UPDATE" == 1 ]
        then
            warn_msg "Forced update enabled!"
            PACARGS="-dd"
    fi
    QUIET_MODE=1 NO_NVIDIA_CHECK=1 bwrun /usr/bin/bash -c \
        "/usr/bin/pac -Sy archlinux-keyring chaotic-keyring \
        blackarch-keyring --needed --noconfirm && \
        /usr/bin/pac -Su $PACARGS --noconfirm --overwrite '*'"
    UPDATE_STATUS="$?"
    if [ "$UPDATE_STATUS" == 0 ]
        then
            if [ -n "$(ls -A "$RUNROOTFS/var/cache/pacman/pkg/" 2>/dev/null)" ]
                then
                    if [ -n "$RUNIMAGE" ]
                        then
                            (cd "$RUNIMAGEDIR" && \
                            bash "$RUNROOTFS/usr/bin/runbuild" "$@")
                            UPDATE_STATUS="$?"
                    fi
                    [ "$UPDATE_STATUS" == 0 ] && \
                        info_msg "Update completed!"
                else
                    info_msg "No package updates found!"
            fi
    fi
    [ "$UPDATE_STATUS" != 0 ] && \
        error_msg "The update failed!"
    return $UPDATE_STATUS
}

print_help() {
if ! console_info_notify
    then
        RUNHOSTNAME="$(uname -a|awk '{print$2}')"
    echo -e "
${GREEN}RunImage ${RED}v${RUNIMAGE_VERSION} ${GREEN}by $DEVELOPERS
    ${RED}Usage:
        $RED┌──[$GREEN$RUNUSER$YELLOW@$BLUE${RUNHOSTNAME}$RED]─[$GREEN$PWD$RED]
        $RED└──╼ \$$GREEN $([ -n "$ARGV0" ] && echo "$ARGV0"||echo "$0")$YELLOW {bubblewrap args} $GREEN{executable} $YELLOW{executable args}

        ${BLUE}--run-help   ${RED}|${BLUE}--rH$GREEN                    Show this usage info
        ${BLUE}--run-bwhelp ${RED}|${BLUE}--rBwh$GREEN                  Show Bubblewrap usage info
        ${BLUE}--run-version${RED}|${BLUE}--rV$GREEN                    Show runimage, rootfs, static, runtime version
        ${BLUE}--run-pkglist${RED}|${BLUE}--rP$GREEN                    Show packages installed in runimage
        ${BLUE}--run-binlist${RED}|${BLUE}--rBin$GREEN                  Show /usr/bin in runimage
        ${BLUE}--run-shell  ${RED}|${BLUE}--rS$YELLOW  {args}$GREEN            Run runimage shell or execute a command in runimage shell
        ${BLUE}--run-desktop${RED}|${BLUE}--rD$GREEN                    Launch runimage desktop
        ${BLUE}--overfs-list${RED}|${BLUE}--oL$GREEN                    Show the list of runimage OverlayFS
        ${BLUE}--overfs-rm  ${RED}|${BLUE}--oR$YELLOW  {id id ...|all}$GREEN   Remove OverlayFS
        ${BLUE}--run-build  ${RED}|${BLUE}--rB$YELLOW  {build args}$GREEN      Build new runimage container
        ${BLUE}--run-update ${RED}|${BLUE}--rU$YELLOW  {build args}$GREEN      Update packages and rebuild runimage
        ${BLUE}--run-kill   ${RED}|${BLUE}--rK$GREEN                    Kill all running runimage containers
        ${BLUE}--run-procmon${RED}|${BLUE}--rPm$YELLOW {RUNPIDs}$GREEN         Monitoring of processes running in runimage containers
        ${BLUE}--run-attach ${RED}|${BLUE}--rA$YELLOW  {RUNPID} {args}$GREEN   Attach to a running runimage container or exec command

    ${RED}Only for not extracted (RunImage runtime options):
        ${BLUE}--runtime-extract$YELLOW {pattern}$GREEN          Extract content from embedded filesystem image
        ${BLUE}--runtime-extract-and-run $YELLOW{args}$GREEN     Run runimage afer extraction without using FUSE
        ${BLUE}--runtime-help$GREEN                       Show runimage runtime help (Shown in this help)
        ${BLUE}--runtime-mount$GREEN                      Mount embedded filesystem image and print
        ${BLUE}--runtime-offset$GREEN                     Print byte offset to start of embedded
        ${BLUE}--runtime-portable-home$GREEN              Create a portable home folder to use as ${YELLOW}\$HOME$GREEN
        ${BLUE}--runtime-portable-config$GREEN            Create a portable config folder to use as ${YELLOW}\$XDG_CONFIG_HOME$GREEN
        ${BLUE}--runtime-version$GREEN                    Print version of runimage runtime

    ${RED}Environment variables to configure:
        ${YELLOW}NO_NET$GREEN=1                             Disables network access
        ${YELLOW}TMP_HOME$GREEN=1                           Creates tmpfs /home/${YELLOW}\$USER${GREEN} and /root in RAM and uses it as ${YELLOW}\$HOME
        ${YELLOW}TMP_HOME_DL$GREEN=1                        As above, but with binding ${YELLOW}\$HOME${GREEN}/Downloads directory
        ${YELLOW}SANDBOX_HOME$GREEN=1                       Creates sandbox home directory and bind it to /home/${YELLOW}\$USER${GREEN} or to /root
        ${YELLOW}SANDBOX_HOME_DL$GREEN=1                    As above, but with binding ${YELLOW}\$HOME${GREEN}/Downloads directory
        ${YELLOW}PORTABLE_HOME$GREEN=1                      Creates a portable home directory and uses it as ${YELLOW}\$HOME
        ${YELLOW}PORTABLE_CONFIG$GREEN=1                    Creates a portable config directory and uses it as ${YELLOW}\$XDG_CONFIG_HOME
        ${YELLOW}NO_CLEANUP$GREEN=1                         Disables unmounting and cleanup mountpoints
        ${YELLOW}ALLOW_BG$GREEN=1                           Allows you to run processes in the background and exit the container
        ${YELLOW}NO_NVIDIA_CHECK$GREEN=1                    Disables checking the nvidia driver version
        ${YELLOW}SQFUSE_REMOUNT$GREEN=1                     Remounts the container using squashfuse (fix MangoHud and VkBasalt bug)
        ${YELLOW}OVERFS_MODE$GREEN=1                        Enables OverlayFS mode
        ${YELLOW}KEEP_OVERFS$GREEN=1                        Enables OverlayFS mode with saving after closing runimage
        ${YELLOW}OVERFS_ID$GREEN=ID                         Specifies the OverlayFS ID
        ${YELLOW}KEEP_OLD_BUILD$GREEN=1                     Creates a backup of the old RunImage when building a new one
        ${YELLOW}BUILD_WITH_EXTENSION$GREEN=1               Adds an extension when building (compression method and rootfs type)
        ${YELLOW}RUN_SHELL$GREEN=\"shell\"                    Selects ${YELLOW}\$SHELL$GREEN in runimage
        ${YELLOW}NO_CAP$GREEN=1                             Disables Bubblewrap capabilities (Default: ALL, drop CAP_SYS_NICE)
                                                you can also use /usr/bin/nocap in runimage
        ${YELLOW}AUTORUN$GREEN=\"{executable} {args}\"        Run runimage with autorun options for /usr/bin executables
        ${YELLOW}ALLOW_ROOT$GREEN=1                         Allows to run runimage under root user
        ${YELLOW}QUIET_MODE$GREEN=1                         Disables all non-error runimage messages
        ${YELLOW}DONT_NOTIFY$GREEN=1                        Disables all non-error runimage notification
        ${YELLOW}UNSHARE_PIDS$GREEN=1                       Hides all system processes in runimage
        ${YELLOW}RUNTIME_EXTRACT_AND_RUN$GREEN=1            Run runimage afer extraction without using FUSE
        ${YELLOW}TMPDIR$GREEN=\"/path/{TMPDIR}\"              Used for extract and run options
        ${YELLOW}RUNIMAGE_CONFIG$GREEN=\"/path/{config}\"     runimage сonfiguration file (0 to disable)
        ${YELLOW}ENABLE_HOSTEXEC$GREEN=1                    Enables the ability to execute commands at the host level
        ${YELLOW}NO_RPIDSMON$GREEN=1                        Disables the monitoring thread of running processes
        ${YELLOW}FORCE_UPDATE$GREEN=1                       Disables all checks when updating
        ${YELLOW}SANDBOX_NET$GREEN=1                        Creates a network sandbox
        ${YELLOW}SANDBOX_NET_CIDR$GREEN=11.22.33.0/24       Specifies tap interface subnet in network sandbox (Def: 10.0.2.0/24)
        ${YELLOW}SANDBOX_NET_TAPNAME$GREEN=tap0             Specifies tap interface name in network sandbox (Def: eth0)
        ${YELLOW}SANDBOX_NET_MAC$GREEN=B6:40:E0:8B:A6:D7    Specifies tap interface MAC in network sandbox (Def: random)
        ${YELLOW}SANDBOX_NET_MTU$GREEN=65520                Specifies tap interface MTU in network sandbox (Def: 1500)
        ${YELLOW}SANDBOX_NET_HOSTS$GREEN=\"file\"             Binds specified file to /etc/hosts in network sandbox
        ${YELLOW}SANDBOX_NET_RESOLVCONF$GREEN=\"file\"        Binds specified file to /etc/resolv.conf in network sandbox
        ${YELLOW}BWRAP_ARGS$GREEN+=()                       Array with Bubblewrap arguments (for config file)
        ${YELLOW}EXEC_ARGS$GREEN+=()                        Array with Bubblewrap exec arguments (for config file)
        ${YELLOW}NO_BWRAP_WAIT$GREEN=1                      Disables the delay when closing the container too quickly
        ${YELLOW}XORG_CONF$GREEN=\"/path/xorg.conf\"          Binds xorg.conf to /etc/X11/xorg.conf in runimage (0 to disable)
                                                (Default: /etc/X11/xorg.conf bind from the system)
        ${YELLOW}XEPHYR_SIZE$GREEN=\"HEIGHTxWIDTH\"           Sets runimage desktop resolution (Default: 1600x900)
        ${YELLOW}XEPHYR_DISPLAY$GREEN=\":9999\"               Sets runimage desktop ${YELLOW}\$DISPLAY$GREEN (Default: :1337)
        ${YELLOW}XEPHYR_FULLSCREEN$GREEN=1                  Starts runimage desktop in full screen mode
        ${YELLOW}UNSHARE_CLIPBOARD$GREEN=1                  Disables clipboard synchronization for runimage desktop

        ${YELLOW}SYS_BWRAP$GREEN=1                          Using system ${BLUE}bwrap
        ${YELLOW}SYS_SQFUSE$GREEN=1                         Using system ${BLUE}squashfuse
        ${YELLOW}SYS_UNSQFS$GREEN=1                         Using system ${BLUE}unsquashfs
        ${YELLOW}SYS_MKSQFS$GREEN=1                         Using system ${BLUE}mksquashfs
        ${YELLOW}SYS_FOVERFS$GREEN=1                        Using system ${BLUE}fuse-overlayfs
        ${YELLOW}SYS_SLIRP$GREEN=1                          Using system ${BLUE}slirp4netns
        ${YELLOW}SYS_TOOLS$GREEN=1                          Using all these binaries from the system
                                             If they are not found in the system - auto return to the built-in

    ${RED}Other environment variables:
        ${GREEN}RunImage path (for packed):
            ${YELLOW}RUNIMAGE${GREEN}=\"$RUNIMAGE\"
        ${GREEN}Squashfs offset (for packed):
            ${YELLOW}RUNOFFSET${GREEN}=\"$RUNOFFSET\"
        ${GREEN}Null argument:
            ${YELLOW}ARGV0${GREEN}=\"$ARGV0\"
        ${GREEN}PID of Run.sh script:
            ${YELLOW}RUNPID${GREEN}=\"$RUNPID\"
        ${GREEN}Parent PID of Run.sh script:
            ${YELLOW}RUNPPID${GREEN}=\"$RUNPPID\"
        ${GREEN}Run binary directory:
            ${YELLOW}RUNDIR${GREEN}=\"$RUNDIR\"
        ${GREEN}RootFS directory:
            ${YELLOW}RUNROOTFS${GREEN}=\"$RUNROOTFS\"
        ${GREEN}Static binaries directory:
            ${YELLOW}RUNSTATIC${GREEN}=\"$RUNSTATIC\"
        ${GREEN}RunImage or RunDir directory:
            ${YELLOW}RUNIMAGEDIR${GREEN}=\"$RUNIMAGEDIR\"
        ${GREEN}Sandbox homes directory:
            ${YELLOW}SANDBOXHOMEDIR${GREEN}=\"$SANDBOXHOMEDIR\"
        ${GREEN}Portable homes directory:
            ${YELLOW}PORTABLEHOMEDIR${GREEN}=\"$PORTABLEHOMEDIR\"
        ${GREEN}External configs directory:
            ${YELLOW}RUNCONFIGDIR${GREEN}=\"$RUNCONFIGDIR\"
        ${GREEN}Cache directory:
            ${YELLOW}RUNCACHEDIR${GREEN}=\"$RUNCACHEDIR\"
        ${GREEN}RunImage name or link name or executable name:
            ${YELLOW}RUNSRCNAME${GREEN}=\"$RUNCACHEDIR\"
        ${GREEN}RunImage version:
            ${YELLOW}RUNIMAGE_VERSION${GREEN}=\"$RUNIMAGE_VERSION\"
        ${GREEN}RootFS version:
            ${YELLOW}RUNROOTFS_VERSION${GREEN}=\"$RUNROOTFS_VERSION\"
        ${GREEN}Static version:
            ${YELLOW}RUNSTATIC_VERSION${GREEN}=\"$RUNSTATIC_VERSION\"
        ${GREEN}RunImage runtime version:
            ${YELLOW}RUNRUNTIME_VERSION${GREEN}=\"$RUNRUNTIME_VERSION\"
        ${GREEN}Directory for all OverlayFS:
            ${YELLOW}RUNOVERFSDIR${GREEN}=\"$RUNOVERFSDIR\"
        ${GREEN}OverlayFS ID directory:
            ${YELLOW}OVERFS_DIR${GREEN}=\"$OVERFS_DIR\"
        ${GREEN}OverlayFS ID mount directory:
            ${YELLOW}OVERFS_MNT${GREEN}=\"$OVERFS_MNT\"
        ${GREEN}RunImage runtime:
            ${YELLOW}RUNRUNTIME${GREEN}=\"$RUNRUNTIME\"
        ${GREEN}Rootfs type:
            ${YELLOW}RUNROOTFSTYPE${GREEN}=\"$RUNROOTFSTYPE\"
        ${GREEN}squashfuse and fuse-overlayfs PIDs:
            ${YELLOW}FUSE_PIDS${GREEN}=\"$FUSE_PIDS\"
        ${GREEN}The name of the user who runs runimage:
            ${YELLOW}RUNUSER${GREEN}=\"$RUNUSER\"
        ${GREEN}mksquashfs:
            ${YELLOW}MKSQFS${GREEN}=\"$MKSQFS\"
        ${GREEN}unsquashfs:
            ${YELLOW}UNSQFS${GREEN}=\"$UNSQFS\"
        ${GREEN}fuse-overlayfs:
            ${YELLOW}FOVERFS${GREEN}=\"$FOVERFS\"
        ${GREEN}squashfuse:
            ${YELLOW}SQFUSE${GREEN}=\"$SQFUSE\"
        ${GREEN}bwrap:
            ${YELLOW}BWRAP${GREEN}=\"$BWRAP\"
        ${GREEN}slirp4netns:
            ${YELLOW}SLIRP${GREEN}=\"$SLIRP\"

    ${RED}Custom scripts and aliases:
        ${YELLOW}/bin/cip$GREEN                          Сheck public ip
        ${YELLOW}/bin/dbus-flmgr$GREEN                   Launch the system file manager via dbus
        ${YELLOW}/bin/nocap$GREEN                        Disables container capabilities
        ${YELLOW}/bin/sudo$GREEN                         Fake sudo (fakechroot fakeroot)
        ${YELLOW}/bin/pac$GREEN                          sudo pacman (fake sudo)
        ${YELLOW}/bin/packey$GREEN                       sudo pacman-key (fake sudo)
        ${YELLOW}/bin/panelipmon$GREEN                   Shows information about an active network connection
        ${YELLOW}/bin/runbuild$GREEN                     Starts the runimage build
        ${YELLOW}/bin/rundesktop$GREEN                   Starts the desktop mode
        ${YELLOW}/bin/{xclipsync,xclipfrom}$GREEN        For clipboard synchronization in desktop mode
        ${YELLOW}/bin/webm2gif$GREEN                     Convert webm to gif
        ${YELLOW}/bin/transfer$GREEN                     Upload file to ${BLUE}https://transfer.sh
        ${YELLOW}/bin/rpidsmon$GREEN                     For monitoring of processes running in runimage containers
        ${YELLOW}/bin/hostexec$GREEN                     For execute commands at the host level (see ${YELLOW}ENABLE_HOSTEXEC$GREEN)

        ${YELLOW}ls$GREEN='ls --color=auto'
        ${YELLOW}dir$GREEN='dir --color=auto'
        ${YELLOW}grep$GREEN='grep --color=auto'
        ${YELLOW}vdir$GREEN='vdir --color=auto'
        ${YELLOW}fgrep$GREEN='fgrep --color=auto'
        ${YELLOW}egrep$GREEN='egrep --color=auto'
        ${YELLOW}rm$GREEN='rm -i'
        ${YELLOW}cp$GREEN='cp -i'
        ${YELLOW}mv$GREEN='mv -i'
        ${YELLOW}ll$GREEN='ls -lh'
        ${YELLOW}la$GREEN='ls -lha'
        ${YELLOW}l$GREEN='ls -CF'
        ${YELLOW}em$GREEN='emacs -nw'
        ${YELLOW}_$GREEN='sudo'
        ${YELLOW}_i$GREEN='sudo -i'
        ${YELLOW}please$GREEN='sudo'
        ${YELLOW}fucking$GREEN='sudo'
        ${YELLOW}cip$GREEN='curl -s ifconfig.io 2>/dev/null'
        ${YELLOW}dd$GREEN='dd status=progress'
        ${YELLOW}pac$GREEN='sudo pacman'
        ${YELLOW}pacman$GREEN='sudo pacman'
        ${YELLOW}pacman-key$GREEN='sudo pacman-key'
        ${YELLOW}packey$GREEN='sudo pacman-key'

    ${RED}Additional information:${GREEN}
        You can create a symlink/hardlink to runimage or rename runimage and give it the name
            of some executable file from /usr/bin in runimage, this will allow you to run
            runimage in autorun mode for this executable file.
        The same principle applies to the ${YELLOW}AUTORUN$GREEN variable:
            $RED┌─[$GREEN$RUNUSER$YELLOW@$BLUE${RUNHOSTNAME}$RED]─[$GREEN$PWD$RED]
            $RED└──╼ \$ ${YELLOW}AUTORUN=\"ls -la\" ${GREEN}runimage ${YELLOW}{autorun executable args}${GREEN}
        Here runimage will become something like an alias for 'ls' in runimage
            with the '-la' argument. You can also use ${YELLOW}AUTORUN${GREEN} as an array for complex commands in the config.
            ${YELLOW}AUTORUN=(\"ls\" \"-la\" \"/path/to something\")${GREEN}
        This will also work in extracted form for the Run binary.

        When using the ${YELLOW}PORTABLE_HOME$GREEN and ${YELLOW}PORTABLE_CONFIG$GREEN variables, runimage will create or
            search for these directories next to itself. The same behavior will occur when
            adding a runimage or Run binary or renamed or symlink/hardlink to them in the PATH
            it can be used both extracted and compressed and for all executable files being run:
                ${YELLOW}'$PORTABLEHOMEDIR/Run'$GREEN
                ${YELLOW}'$RUNIMAGEDIR/Run.config'$GREEN
            if a symlink/hardlink to runimage is used:
                ${YELLOW}'$PORTABLEHOMEDIR/{symlink/hardlink_name}'$GREEN
                ${YELLOW}'$RUNIMAGEDIR/{symlink/hardlink_name}.config'$GREEN
            or with runimage/Run name:
                ${YELLOW}'$PORTABLEHOMEDIR/{runimage/Run_name}'$GREEN
                ${YELLOW}'$RUNIMAGEDIR/{runimage/Run_name}.config'$GREEN
            It can also be with the name of the executable file from ${YELLOW}AUTORUN$GREEN environment variables,
                or with the same name as the executable being run.
        ${YELLOW}SANDBOX_HOME$GREEN* similar to ${YELLOW}PORTABLE_HOME$GREEN, but the system ${YELLOW}HOME$GREEN becomes isolated.

        RunImage uses fakeroot and fakechroot, which allows you to use root commands, including in
            unpacked form, to update the rootfs or install/remove packages.
            sudo and pkexec have also been replaced with fake ones. (see /usr/bin/sudo /usr/bin/pkexec)

        ${RED}RunImage configuration file:${GREEN}
            Special BASH-syntax file with the .rcfg extension, which describes additional
                instructions and environment variables for running runimage.
            Configuration file can be located next to runimage:
                ${YELLOW}'$RUNIMAGEDIR/{runimage/Run_name}.rcfg'$GREEN
            it can be used both extracted and compressed and for all executable files being run:
                ${YELLOW}'$RUNIMAGEDIR/Run.rcfg'$GREEN
            if a symlink/hardlink to runimage is used:
                ${YELLOW}'$RUNIMAGEDIR/{symlink/hardlink_name}.rcfg'$GREEN
            or in ${YELLOW}\$RUNIMAGEDIR$GREEN/config directory:
                ${YELLOW}'$RUNCONFIGDIR/Run.rcfg'$GREEN
                ${YELLOW}'$RUNCONFIGDIR/{runimage/Run_name}.rcfg'$GREEN
                ${YELLOW}'$RUNCONFIGDIR/{symlink/hardlink_name}.rcfg'$GREEN
            It can also be with the name of the executable file from ${YELLOW}AUTORUN$GREEN environment variables,
                or with the same name as the executable being run.
            In ${YELLOW}\$RUNDIR$GREEN/config there are default configs in RunImage, they are run in priority,
                then external configs are run if they are found.

        ${RED}RunImage desktop:${GREEN}
            Ability to run RunImage in desktop mode. Default DE: XFCE (see /usr/bin/rundesktop)
            If the launch is carried out from an already running desktop, then Xephyr will start
                in windowed mode (see ${YELLOW}XEPHYR_*$GREEN environment variables)
                Use CTRL+SHIFT to grab the keyboard and mouse.
            It is also possible to run on TTY with Xorg (see ${YELLOW}XORG_CONF$GREEN environment variables)
                To do this, just log in to TTY and run RunImage desktop.
            ${RED}Important!${GREEN} The launch on the TTY should be carried out only under the user under whom the
                login to the TTY was carried out.

        ${RED}RunImage OverlayFS:${GREEN}
            Allows you to create additional separate layers to modify the container file system without
                changing the original container file system. Works packed and unpacked. Also, in packed form,
                it allows you to mount the container in RW mode.
            It also allows you to attach to the same OverlayFS when you specify its ID:
            $RED┌─[$GREEN$RUNUSER$YELLOW@$BLUE${RUNHOSTNAME}$RED]─[$GREEN$PWD$RED]
            $RED└──╼ \$ ${YELLOW}OVERFS_ID=1337 ${GREEN}runimage ${YELLOW}{args}${GREEN}
                If OverlayFS with such ID does not exist, it will be created.
            To save OverlayFS after closing the container, use ${YELLOW}KEEP_OVERFS:
            $RED┌─[$GREEN$RUNUSER$YELLOW@$BLUE${RUNHOSTNAME}$RED]─[$GREEN$PWD$RED]
            $RED└──╼ \$ ${YELLOW}KEEP_OVERFS=1 ${GREEN}runimage ${YELLOW}{args}${GREEN}
            To run a one-time OverlayFS, use ${YELLOW}OVERFS_MODE:
            $RED┌─[$GREEN$RUNUSER$YELLOW@$BLUE${RUNHOSTNAME}$RED]─[$GREEN$PWD$RED]
            $RED└──╼ \$ ${YELLOW}OVERFS_MODE=1 ${GREEN}runimage ${YELLOW}{args}${GREEN}

        ${RED}RunImage build:${GREEN}
            Allows you to create your own runimage containers.
            This works both externally by passing build args:
            $RED┌─[$GREEN$RUNUSER$YELLOW@$BLUE${RUNHOSTNAME}$RED]─[$GREEN$PWD$RED]
            $RED└──╼ \$ ${GREEN}runimage ${BLUE}--run-build ${YELLOW}{build args}${GREEN}
            And it also works inside the running instance (see /bin/runbuild):
            $RED┌─[$GREEN$RUNUSER$YELLOW@$BLUE${RUNHOSTNAME}$RED]─[$GREEN$PWD$RED] - in runimage
            $RED└──╼ \$ ${GREEN}runbuild ${YELLOW}{build args}${GREEN}
            Optionally, you can specify the following build arguments:
                ${YELLOW}{/path/new_runimage_name} {-zstd|-xz} {zstd compression level 1-19}${GREEN}
            By default, runimage is created in the current directory with a standard name and
                with lz4 compression. If a new RunImage is successfully build, the old one is deleted.
                (see ${YELLOW}KEEP_OLD_BUILD${GREEN} and ${YELLOW}BUILD_WITH_EXTENSION${GREEN})

        ${RED}RunImage update:${GREEN}
            Allows you to update packages and rebuild RunImage. In unpacked form, automatic build will
                not be performed. When running an update, you can also pass arguments for a new build.
                (see RunImage build) (also see ${YELLOW}FORCE_UPDATE${GREEN})
            $RED┌─[$GREEN$RUNUSER$YELLOW@$BLUE${RUNHOSTNAME}$RED]─[$GREEN$PWD$RED]
            $RED└──╼ \$ ${GREEN}runimage ${BLUE}--run-update ${YELLOW}{build args}${GREEN}
            By default, update and rebuild is performed in ${YELLOW}\$RUNIMAGEDIR${GREEN}

        ${RED}RunImage network sandbox:${GREEN}
            Allows you to create a private network namespace with slirp4netns and inside the container
                manage routing, create/delete network interfaces, connect to a vpn (checked openvpn
                and wireguard), configure your resolv.conf and hosts, etc. (see ${YELLOW}SANDBOX_NET${GREEN}*)
            By default, network sandbox created in 10.0.2.0/24 subnet, with eth0 tap name, 10.0.2.100 tap ip,
                1500 tap MTU, and random MAC.

        ${RED}RunImage hostexec:${GREEN}
            Allows you to run commands at the host level (see ${YELLOW}ENABLE_HOSTEXEC${GREEN} and /usr/bin/hostexec)
            $RED┌─[$GREEN$RUNUSER$YELLOW@$BLUE${RUNHOSTNAME}$RED]─[$GREEN$PWD$RED]
            $RED└──╼ \$ ${YELLOW}ENABLE_HOSTEXEC${GREEN}=1 runimage ${BLUE}--run-shell ${GREEN}
            $RED┌─[$GREEN$RUNUSER$YELLOW@$BLUE${RUNHOSTNAME}$RED]─[$GREEN$PWD$RED] - pass command as args
            $RED└──╼ \$ ${GREEN}hostexec ${BLUE}{hostexec args}${GREEN} {executable} ${YELLOW}{executable args}${GREEN}
            $RED┌─[$GREEN$RUNUSER$YELLOW@$BLUE${RUNHOSTNAME}$RED]─[$GREEN$PWD$RED] - pass command to stdin
            $RED└──╼ \$ ${GREEN}echo ${BLUE}\"${GREEN}{executable}${YELLOW} {executable args}${BLUE}\"$RED|${GREEN}hostexec ${BLUE}{hostexec args}${GREEN}
                ${BLUE}--help        |-h${GREEN}             Show this usage info
                ${BLUE}--superuser   |-su${GREEN}            Execute command as superuser
                ${BLUE}--interactive |-i${GREEN}             Execute interactive command (with input prompt)

        ${RED}For Nvidia users with a proprietary driver:${GREEN}
            If the nvidia driver version does not match in runimage and in the host, runimage
                will make an image with the nvidia driver of the required version (requires internet)
                or will download a ready-made image from the github repository and further used as
                an additional module to runimage.
            You can download a ready-made driver image from the releases or build driver image manually:
                ${BLUE}https://github.com/VHSgunzo/runimage-nvidia-drivers${GREEN}
            In runimage, a fake version of the nvidia driver is installed by default to reduce the size:
                ${BLUE}https://github.com/VHSgunzo/runimage-fake-nvidia-utils${GREEN}
            But you can also install the usual nvidia driver of your version in runimage.
            Checking the nvidia driver version can be disabled using ${YELLOW}NO_NVIDIA_CHECK$GREEN variable.
            The nvidia driver image can be located next to runimage:
                    ${YELLOW}'$RUNIMAGEDIR/{nvidia_version}.nv.drv'$GREEN
                or in ${YELLOW}\$RUNIMAGEDIR$GREEN/nvidia-drivers (Default):
                    ${YELLOW}'$RUNIMAGEDIR/nvidia-drivers/{nvidia_version}.nv.drv'$GREEN
                or the driver can be extracted as the directory
                    ${YELLOW}'$RUNIMAGEDIR/nvidia-drivers/{nvidia_version}'$GREEN
                also, the driver can be in RunImage in a packed or unpacked form:
                    ${YELLOW}'\$RUNDIR/nvidia-drivers/{nvidia_version}.nv.drv'$GREEN   ${RED}-  image
                    ${YELLOW}'\$RUNDIR/nvidia-drivers/{nvidia_version}'$GREEN          ${RED}-  directory

    ${RED}Recommendations:${GREEN}
        If the kernel does not support user namespaces, you need to install
            SUID Bubblewrap into the system, or install a kernel with user namespaces support.
            If SUID Bubblewrap is found in the system, it will be used automatically.
        If you use SUID Bubblewrap, then you will encounter some limitations, such as the inability to use
            FUSE in RunImage, without running it under the root user, because the capabilities are
            disabled, and so on. So it would be better for you to install kernel with
            user namespaces support.
        I recommend installing the XanMod kernel (${BLUE}https://xanmod.org${GREEN}), because I noticed that the speed
            of runimage in compressed form on this kernel is much higher due to more correct caching settings
            and special patches.
    $RESETCOLOR" >&2
fi
}

if [[ "$EUID" == 0 && "$ALLOW_ROOT" != 1 ]]
    then
        error_msg "root user is not allowed!"
        if ! console_info_notify
            then
                echo -e "${RED}\t\t\tDo not run RunImage as root!"
                echo -e "If you really need to run it as root set the ${YELLOW}ALLOW_ROOT${GREEN}=1 ${RED}environment variable.$RESETCOLOR"
                exit 1
        fi
fi

if [ -n "$AUTORUN" ] && \
   [[ "$RUNSRCNAME" == "Run"* || \
      "$RUNSRCNAME" == "runimage"* ]]
    then
        RUNSRCNAME=($AUTORUN)
elif [[ "$RUNSRCNAME" != "Run"* && \
        "$RUNSRCNAME" != "runimage"* ]]
   then
        AUTORUN="$RUNSRCNAME"
fi

if [[ -n "$1" && ! -n "$AUTORUN" ]]
    then
        case $1 in
            --*) : ;;
            *) RUNSRCNAME="$(basename "$1")"
            ;;
        esac
fi

[ "$RUNROOTFSTYPE" == "superlite" ] && \
    SQFUSE_REMOUNT=1

if [ "$RUNIMAGE_CONFIG" != 0 ]
    then
        if [ -f "$RUNDIR/config/$RUNSRCNAME.rcfg" ]
            then
                RUNIMAGE_INTERNAL_CONFIG="$RUNDIR/config/$RUNSRCNAME.rcfg"
                SET_RUNIMAGE_INTERNAL_CONFIG=1
        elif [ -f "$RUNDIR/config/Run.rcfg" ]
            then
                RUNIMAGE_INTERNAL_CONFIG="$RUNDIR/config/Run.rcfg"
                SET_RUNIMAGE_INTERNAL_CONFIG=1
        fi
        if [ "$SET_RUNIMAGE_INTERNAL_CONFIG" == 1 ]
            then
                set -a
                source "$RUNIMAGE_INTERNAL_CONFIG"
                set +a
                info_msg "Found RunImage internal config: $(basename "$RUNIMAGE_INTERNAL_CONFIG")"
        fi
        if [[ -f "$RUNIMAGE_CONFIG" && -n "$(echo "$RUNIMAGE_CONFIG"|grep -o '\.rcfg$')" ]]
            then
                SET_RUNIMAGE_CONFIG=1
        elif [ -f "$RUNIMAGEDIR/$RUNSRCNAME.rcfg" ]
            then
                RUNIMAGE_CONFIG="$RUNIMAGEDIR/$RUNSRCNAME.rcfg"
                SET_RUNIMAGE_CONFIG=1
        elif [ -f "$RUNCONFIGDIR/$RUNSRCNAME.rcfg" ]
            then
                RUNIMAGE_CONFIG="$RUNCONFIGDIR/$RUNSRCNAME.rcfg"
                SET_RUNIMAGE_CONFIG=1
        elif [[ -n "$RUNIMAGE" && -f "$RUNIMAGE.rcfg" ]]
            then
                RUNIMAGE_CONFIG="$RUNIMAGE.rcfg"
                SET_RUNIMAGE_CONFIG=1
        elif [ -f "$RUNIMAGEDIR/Run.rcfg" ]
            then
                RUNIMAGE_CONFIG="$RUNIMAGEDIR/Run.rcfg"
                SET_RUNIMAGE_CONFIG=1
        elif [ -f "$RUNCONFIGDIR/Run.rcfg" ]
            then
                RUNIMAGE_CONFIG="$RUNCONFIGDIR/Run.rcfg"
                SET_RUNIMAGE_CONFIG=1
        fi
        if [ "$SET_RUNIMAGE_CONFIG" == 1 ]
            then
                set -a
                source "$RUNIMAGE_CONFIG"
                set +a
                info_msg "Found RunImage config: '$RUNIMAGE_CONFIG'"
        fi
    else
        warn_msg "RunImage config is disabled!"
fi

if [[ "$RUNSRCNAME" == "Run"* || \
      "$RUNSRCNAME" == "runimage"* ]]
    then
        case $1 in
            --run-pkglist|--rP|\
            --run-kill   |--rK|\
            --run-help   |--rH|\
            --run-binlist|--rBin|\
            --run-bwhelp |--rBwh|\
            --run-version|--rV|\
            --overfs-list|--oL|\
            --overfs-rm  |--oR|\
            --run-build  |--rB|\
            --run-attach |--rA) SQFUSE_REMOUNT=0 ; ALLOW_BG=0 ;;
            --run-update |--rU) [ -n "$RUNIMAGE" ] && OVERFS_MODE=1
                                SQFUSE_REMOUNT=0 ; ALLOW_BG=0 ;;
            --run-procmon|--rPm) NO_RPIDSMON=1 ; SANDBOX_NET=0 ; SQFUSE_REMOUNT=0
                                 NO_NVIDIA_CHECK=1 ; QUIET_MODE=1 ; ALLOW_BG=0 ;;
        esac
fi

if logname &>/dev/null
    then
        export RUNUSER="$(logname)"
elif [ -n "$SUDO_USER" ]
    then
        export RUNUSER="$SUDO_USER"
elif [[ "$EUID" != 0 && "$USER" != "root" ]] || \
     [[ "$EUID" == 0 && "$USER" != "root" ]]
    then
        export RUNUSER="$USER"
elif [ -n "$(who|grep -m1 'tty'|awk '{print$1}')" ]
    then
        export RUNUSER="$(who|grep -m1 'tty'|awk '{print$1}')"
fi

if [[ "$DISPLAY" == "wayland-"* ]]
    then
        export DISPLAY=":$(echo "$DISPLAY"|sed 's|wayland-||g')"
elif [[ ! -n "$DISPLAY" && ! -n "$WAYLAND_DISPLAY" ]]
    then
        export DISPLAY="$(who|grep "$RUNUSER"|grep -v "ttyS"|\
                          grep -om1 '(.*)$'|sed 's/(//;s/)//')"
fi

xhost +si:localuser:$RUNUSER &>/dev/null
[[ "$EUID" == 0 && "$RUNUSER" != "root" ]] && \
    xhost +si:localuser:root &>/dev/null

if [[ ! -n "$XDG_RUNTIME_DIR" || "$XDG_RUNTIME_DIR" != "/run/user/$EUID" || "$UNSHARE_PIDS" == 1 ]]
    then
        export XDG_RUNTIME_DIR="/run/user/$EUID"
        if [[ "$UNSHARE_PIDS" == 1 || ! -d "$XDG_RUNTIME_DIR" ]]
            then
                XDG_RUN_BIND+=("--tmpfs" "/run" \
                               "--dir" "$XDG_RUNTIME_DIR" \
                               "--chmod" "0700" "$XDG_RUNTIME_DIR")
                if [ ! -d "$XDG_RUNTIME_DIR" ]
                    then
                        for i_run in /run/* /run/.[a-zA-Z0-9]*
                            do
                                [ "$i_run" != "/run/user" ] && \
                                    XDG_RUN_BIND+=("--bind-try" "$i_run" "$i_run")
                        done
                fi
            else
                XDG_RUN_BIND=("--bind-try" "/run" "/run")
        fi
    else
        XDG_RUN_BIND=("--bind-try" "/run" "/run")
fi

if [ "$NO_RPIDSMON" != 1 ]
    then
        "$RUNSTATIC/headpid" $RUNPID &
        headpid=$!
        (wait_rpids=15
        oldrpids="$(get_child_pids "$headpid")"
        while ps -o pid= -p $oldrpids &>/dev/null
            do
                newrpids="$(get_child_pids "$headpid")"
                if [ ! -n "$(echo "$newrpids"|grep -v "$headpid")" ]
                    then
                        if [ "$wait_rpids" -gt 0 ]
                            then
                                wait_rpids="$(( $wait_rpids - 1 ))"
                                sleep 0.01
                                continue
                        fi
                        break
                    else
                        if [ -n "$newrpids" ]
                            then
                                if [[ -n "$(echo -e "$newrpids\n$oldrpids"|\
                                    sort -n|uniq -u)" || ! -f "$RPIDSFL" ]]
                                    then
                                        echo "$newrpids" > "$RPIDSFL"
                                        oldrpids="$newrpids"
                                fi
                        fi
                fi
                sleep 0.5
        done
        rm -f "$RPIDSFL" 2>/dev/null
        try_kill $headpid) &
fi

if [ ! -n "$DBUS_SESSION_BUS_ADDRESS" ]
    then
        if [ -S "$XDG_RUNTIME_DIR/bus" ]
            then export DBUS_SESSION_BUS_ADDRESS="unix:path=$XDG_RUNTIME_DIR/bus"
        elif get_dbus_session_bus_address &>/dev/null
            then export $(get_dbus_session_bus_address)
        fi
fi

[ "$SYS_TOOLS" == 1 ] && \
    export SYS_MKSQFS=1 SYS_UNSQFS=1 \
           SYS_SQFUSE=1 SYS_BWRAP=1 \
           SYS_FOVERFS=1 SYS_SLIRP=1

if [ "$SYS_MKSQFS" == 1 ] && is_sys_exe mksquashfs
    then
        info_msg "The system mksquashfs is used!"
        export MKSQFS="$(which_sys_exe mksquashfs)"
    else
        export MKSQFS="$RUNSTATIC/mksquashfs"
fi

if [ "$SYS_UNSQFS" == 1 ] && is_sys_exe unsquashfs
    then
        info_msg "The system unsquashfs is used!"
        export UNSQFS="$(which_sys_exe unsquashfs)"
    else
        export UNSQFS="$RUNSTATIC/unsquashfs"
fi

if [ "$SYS_FOVERFS" == 1 ] && is_sys_exe fuse-overlayfs
    then
        info_msg "The system fuse-overlayfs is used!"
        export FOVERFS="$(which_sys_exe fuse-overlayfs)"
    else
        export FOVERFS="$RUNSTATIC/fuse-overlayfs"
fi

if [ "$SYS_SLIRP" == 1 ] && is_sys_exe slirp4netns
    then
        info_msg "The system slirp4netns is used!"
        export SLIRP="$(which_sys_exe slirp4netns)"
    else
        export SLIRP="$RUNSTATIC/slirp4netns"
fi

if [ "$SYS_SQFUSE" == 1 ] && is_sys_exe squashfuse
    then
        info_msg "The system squashfuse is used!"
        export SQFUSE="$(which_sys_exe squashfuse)"
    else
        [ -x "$(which_sys_exe fusermount3)" ] && \
            export SQFUSE="$RUNSTATIC/squashfuse3" || \
            export SQFUSE="$RUNSTATIC/squashfuse"
fi

if [ "$EUID" != 0 ]
    then
        if [ ! -f '/proc/self/ns/user' ]
            then
                SYS_BWRAP=1
                [ ! -n "$(echo "$PATH"|grep -wo '^/usr/bin:')" ] && \
                    export PATH="/usr/bin:$PATH"
                if [ ! -x "$(find "$(which bwrap 2>/dev/null)" -perm -u=s 2>/dev/null)" ]
                    then
                        [ ! -x '/tmp/bwrap' ] && \
                            rm -rf '/tmp/bwrap' && \
                            cp "$RUNSTATIC/bwrap" '/tmp/'
                        error_msg 'The kernel does not support user namespaces!'
                        if ! console_info_notify
                            then
                                echo -e "${YELLOW}\nYou need to install SUID Bubblewrap into the system:"
                                echo -e "${RED}# ${GREEN}sudo cp -f /tmp/bwrap /usr/bin/ && sudo chmod u+s /usr/bin/bwrap"
                                echo -e "${RED}\n[NOT RECOMMENDED]: ${YELLOW}Or run as the root user."
                                echo -e "${YELLOW}\nOr install a kernel with user namespaces support."
                                echo -e "[RECOMMENDED]: XanMod kernel -> ${BLUE}https://xanmod.org$RESETCOLOR"
                        fi
                        exit 1
                fi
        elif [ "$(cat '/proc/sys/kernel/unprivileged_userns_clone' 2>/dev/null)" == 0 ]
            then
                error_msg "unprivileged_userns_clone is disabled!"
                if ! console_info_notify
                    then
                        echo -e "${YELLOW}\nYou need to enable unprivileged_userns_clone:"
                        echo -e "${RED}# ${GREEN}sudo bash -c 'echo kernel.unprivileged_userns_clone=1 >> /etc/sysctl.d/98-userns.conf'"
                        echo -e "${RED}# ${GREEN}sudo bash -c 'echo 1 > /proc/sys/kernel/unprivileged_userns_clone'$RESETCOLOR"
                fi
                exit 1
        elif [ "$(cat '/proc/sys/user/max_user_namespaces' 2>/dev/null)" == 0 ]
            then
                error_msg "max_user_namespaces is disabled!"
                if ! console_info_notify
                    then
                        echo -e "${YELLOW}\nYou need to enable max_user_namespaces:"
                        echo -e "${RED}# ${GREEN}sudo bash -c 'echo user.max_user_namespaces=10000 >> /etc/sysctl.d/98-userns.conf'"
                        echo -e "${RED}# ${GREEN}sudo bash -c 'echo 10000 > /proc/sys/user/max_user_namespaces'$RESETCOLOR"
                fi
                exit 1
        elif [ "$(cat '/proc/sys/kernel/userns_restrict' 2>/dev/null)" == 1 ]
            then
                error_msg "userns_restrict is enabled!"
                if ! console_info_notify
                    then
                        echo -e "${YELLOW}\nYou need to disabled userns_restrict:"
                        echo -e "${RED}# ${GREEN}sudo bash -c 'echo kernel.userns_restrict=0 >> /etc/sysctl.d/98-userns.conf'"
                        echo -e "${RED}# ${GREEN}sudo bash -c 'echo 0 > /proc/sys/kernel/userns_restrict'$RESETCOLOR"
                fi
                exit 1
        fi
fi

if [ "$SYS_BWRAP" == 1 ] && is_sys_exe bwrap
    then
        info_msg "The system Bubblewrap is used!"
        export BWRAP="$(which_sys_exe bwrap)"
    else
        export BWRAP="$RUNSTATIC/bwrap"
fi
if [[ "$SYS_BWRAP" == 1 && "$EUID" != 0 && \
      -x "$(find "$BWRAP" -perm -u=s 2>/dev/null)" ]]
    then
        warn_msg "Bubblewrap has SUID sticky bit!"
        SUID_BWRAP=1
fi
if [[ "$SUID_BWRAP" == 1 || "$NO_CAP" == 1 ]]
    then
        warn_msg "Bubblewrap capabilities is disabled!"
        BWRAP_CAP=("--cap-drop" "ALL")
    else
        BWRAP_CAP=("--cap-add" "ALL" "${BWRAP_CAP[@]}")
        BWRAP_CAP+=("--cap-drop" "CAP_SYS_NICE") # Gamecope bug https://github.com/Plagman/gamescope/issues/309
fi

[ "$(getenforce 2>/dev/null)" == "Enforcing" ] && \
    warn_msg "SELinux in enforcing mode!"

if [[ -n "$RUNOFFSET" && -n "$RUNIMAGE" && "$SQFUSE_REMOUNT" == 1 ]] # MangoHud and vkBasalt bug in DXVK mode
    then
        info_msg "Remounting RunImage with squashfuse..."
        RO_MNT="/tmp/.mount_${RUNSRCNAME}.$RUNPID"
        try_mkdir "$RO_MNT"
        "$SQFUSE" -f "$RUNIMAGE" "$RO_MNT" -o "ro,offset=$RUNOFFSET" &>/dev/null &
        FUSE_PID="$!"
        export FUSE_PIDS="$FUSE_PID $FUSE_PIDS"
        if ! mount_exist "$FUSE_PID" "$RO_MNT"
            then
                error_msg "Failed to remount RunImage with squashfuse!"
                FORCE_CLEANUP=1 cleanup
                exit 1
        fi
        export RUNROOTFS="$RO_MNT/rootfs"
fi

if [[ "$OVERFS_MODE" == 1 || "$KEEP_OVERFS" == 1 || -n "$OVERFS_ID" ]]
    then
        if [ ! -n "$OVERFS_ID" ]
            then
                export OVERFS_ID=0
                while true
                    do
                        [ ! -d "$RUNOVERFSDIR/$OVERFS_ID" ] && \
                            break
                        export OVERFS_ID="$(( $OVERFS_ID + 1 ))"
                done
        fi
        if [[ -n "$OVERFS_ID" && -d "$RUNOVERFSDIR/$OVERFS_ID" ]]
            then
                [ "$KEEP_OVERFS" != 0 ] && \
                    KEEP_OVERFS=1
                info_msg "Attaching to OverlayFS: $OVERFS_ID"
            else
                info_msg "OverlayFS ID: $OVERFS_ID"
        fi
        export OVERFS_DIR="$RUNOVERFSDIR/$OVERFS_ID"
        try_mkdir "$OVERFS_DIR"
        mkdir -p "$OVERFS_DIR"/{layers,tmp,mnt}
        export OVERFS_MNT="$OVERFS_DIR/mnt"
        "$FOVERFS" -f -o squash_to_uid="$EUID" -o squash_to_gid="$(id -g)" -o \
            lowerdir="$([ -n "$RO_MNT" ] && echo "$RO_MNT"||echo "$RUNDIR"\
            )",upperdir="$OVERFS_DIR/layers",workdir="$OVERFS_DIR/tmp" "$OVERFS_MNT" &
        FOVERFS_PID="$!"
        export FUSE_PIDS="$FOVERFS_PID $FUSE_PIDS"
        if ! mount_exist "$FOVERFS_PID" "$OVERFS_MNT"
            then
                error_msg "Failed to mount RunImage in OverlayFS mode!"
                FORCE_CLEANUP=1 cleanup
                exit 1
        fi
        export RUNROOTFS="$OVERFS_MNT/rootfs"
fi

if [ -n "$AUTORUN" ]
    then
        AUTORUN0ARG=($AUTORUN)
        [ -x "$RUNROOTFS/usr/bin/$AUTORUN0ARG" ] && \
            RUNSRCNAME="$AUTORUN0ARG"
        info_msg "Autorun mode: ${AUTORUN[@]}"
        if [ ! -x "$RUNROOTFS/usr/bin/$AUTORUN0ARG" ]
            then
                error_msg "$AUTORUN0ARG not found in /usr/bin"
                FORCE_CLEANUP=1 cleanup
                exit 1
        fi
fi

if [ ! -n "$RUN_SHELL" ]
    then
        if [ -x "$RUNROOTFS/usr/bin/fish" ]
            then
                RUN_SHELL='/usr/bin/fish'
        elif [ -x "$RUNROOTFS/usr/bin/zsh" ]
            then
                RUN_SHELL='/usr/bin/zsh'
        elif [ -x "$RUNROOTFS/usr/bin/bash" ]
            then
                RUN_SHELL=('/usr/bin/bash' '--rcfile' '/etc/bash.bashrc')
        elif [ -x "$RUNROOTFS/usr/bin/sh" ]
            then
                RUN_SHELL='/usr/bin/sh'
        fi
fi
SETENV_ARGS+=("--setenv" "SHELL" "$RUN_SHELL")

[ -n "$HOME" ] && \
   SYS_HOME="$HOME"

if [[ "$SANDBOX_HOME" != 0 && "$SANDBOX_HOME_DL" != 0 ]]
    then
        if [ -d "$SANDBOXHOMEDIR/$RUNSRCNAME" ]
            then SANDBOX_HOME_DIR="$SANDBOXHOMEDIR/$RUNSRCNAME"
        elif [[ -n "$RUNIMAGE" && -d "$SANDBOXHOMEDIR/$RUNIMAGENAME" ]]
            then SANDBOX_HOME_DIR="$SANDBOXHOMEDIR/$RUNIMAGENAME"
        elif [ -d "$SANDBOXHOMEDIR/Run" ]
            then SANDBOX_HOME_DIR="$SANDBOXHOMEDIR/Run"
        fi
fi

if [[ "$TMP_HOME" == 1 || "$TMP_HOME_DL" == 1 ]]
    then
        [ "$EUID" == 0 ] && \
            export HOME="/root" || \
            export HOME="/home/$RUNUSER"
        HOME_BIND+=("--tmpfs" "/home" \
                    "--tmpfs" "/root" \
                    "--dir" "$HOME/.cache" \
                    "--dir" "$HOME/.config")
        [[ "$EUID" == 0 && "$RUNUSER" != "root" ]] && \
            HOME_BIND+=("--dir" "/home/$RUNUSER")
        [ "$TMP_HOME_DL" == 1 ] && \
            HOME_BIND+=("--dir" "$HOME/Downloads" \
                        "--symlink" "$HOME/Downloads" "$HOME/Загрузки" \
                        "--bind-try" "$HOME/Downloads" "$HOME/Downloads")
        info_msg "Setting temporary \$HOME to: '$HOME'"
elif [[ "$SANDBOX_HOME" == 1 || "$SANDBOX_HOME_DL" == 1 || -d "$SANDBOX_HOME_DIR" ]]
    then
        if [ "$EUID" == 0 ]
            then
                NEW_HOME="/root"
            else
                NEW_HOME="/home/$RUNUSER"
                HOME_BIND+=("--tmpfs" "/home" \
                            "--dir" "$NEW_HOME")
        fi
        HOME_BIND+=("--setenv" "HOME" "$NEW_HOME")
        [ ! -n "$SANDBOX_HOME_DIR" ] && \
            SANDBOX_HOME_DIR="$SANDBOXHOMEDIR/$RUNSRCNAME"
        if [[ "$SANDBOX_HOME" == 1 || "$SANDBOX_HOME_DL" == 1 ]]
            then
                SANDBOX_HOME_DIR="$SANDBOXHOMEDIR/$RUNSRCNAME"
                try_mkhome "$SANDBOX_HOME_DIR"
        fi
        HOME_BIND+=("--bind-try" "$SANDBOX_HOME_DIR" "$NEW_HOME")
        [ "$SANDBOX_HOME_DL" == 1 ] && \
            HOME_BIND+=("--dir" "$NEW_HOME/Downloads" \
                        "--bind-try" "$SYS_HOME/Downloads" "$NEW_HOME/Downloads")
        info_msg "Setting sandbox \$HOME to: '$SANDBOX_HOME_DIR'"
else
    if [[ -n "$SYS_HOME" && "$SYS_HOME" != "/root" && \
        "$(echo "$SYS_HOME"|head -c 6)" != "/home/" ]]
        then
            case "$(echo "$SYS_HOME"|cut -d '/' -f2)" in
                tmp|mnt|media|run|dev|proc|sys) : ;;
                *)
                    if [ "$EUID" == 0 ]
                        then
                            NEW_HOME="/root"
                            HOME_BIND+=("--bind-try" "/home" "/home")
                        else
                            NEW_HOME="/home/$RUNUSER"
                            HOME_BIND+=("--tmpfs" "/home" \
                                        "--tmpfs" "/root" \
                                        "--dir" "$NEW_HOME")
                    fi
                    HOME_BIND+=("--bind-try" "$SYS_HOME" "$NEW_HOME")
                    export HOME="$NEW_HOME"
                ;;
            esac
        else
            HOME_BIND+=("--bind-try" "/home" "/home")
            if [ "$EUID" == 0 ]
                then
                    if [ "$SYS_HOME" == "/home/$RUNUSER" ]
                        then
                            export HOME="/root"
                            SET_HOME_DIR=1
                    fi
                    HOME_BIND+=("--bind-try" "/root" "/root")
                else
                    HOME_BIND+=("--tmpfs" "/root")
            fi
    fi
    if [ "$PORTABLE_HOME" != 0 ]
        then
            if [[ "$PORTABLE_HOME" == 1 || -d "$PORTABLEHOMEDIR/$RUNSRCNAME" ]]
                then
                    export HOME="$PORTABLEHOMEDIR/$RUNSRCNAME"
                    SET_HOME_DIR=1
                    export PORTABLE_HOME=1
            elif [ -n "$RUNIMAGE" ] && [[ "$PORTABLE_HOME" == 1 || -d "$PORTABLEHOMEDIR/$RUNIMAGENAME" ]]
                then
                    export HOME="$PORTABLEHOMEDIR/$RUNIMAGENAME"
                    SET_HOME_DIR=1
                    export PORTABLE_HOME=1
            elif [[ "$PORTABLE_HOME" == 1 || -d "$PORTABLEHOMEDIR/Run" ]]
                then
                    export HOME="$PORTABLEHOMEDIR/Run"
                    SET_HOME_DIR=1
                    export PORTABLE_HOME=1
            fi
    fi
fi
if [[ -L "$HOME" && ! -n "$NEW_HOME" && "$HOME" != "/root" ]]
    then
        export HOME="$(realpath "$HOME" 2>/dev/null)"
        warn_msg "Symlinking for \$HOME is not allowed!"
        SET_HOME_DIR=1
fi
if [ "$SET_HOME_DIR" == 1 ]
    then
        try_mkhome "$HOME"
        info_msg "Setting \$HOME to: '$HOME'"
fi

if [ "$PORTABLE_CONFIG" != 0 ]
    then
        if [[ "$PORTABLE_CONFIG" == 1 || -d "$RUNIMAGEDIR/$RUNSRCNAME.config" ]]
            then
                export XDG_CONFIG_HOME="$RUNIMAGEDIR/$RUNSRCNAME.config"
                SET_CONF_DIR=1
        elif [ -n "$RUNIMAGE" ] && [[ "$PORTABLE_CONFIG" == 1 || -d "$RUNIMAGE.config" ]]
            then
                export XDG_CONFIG_HOME="$RUNIMAGE.config"
                SET_CONF_DIR=1
        elif [[ "$PORTABLE_CONFIG" == 1 || -d "$RUNIMAGEDIR/Run.config" ]]
            then
                export XDG_CONFIG_HOME="$RUNIMAGEDIR/Run.config"
                SET_CONF_DIR=1
        fi
fi
if [ "$SET_CONF_DIR" == 1 ]
    then
        try_mkdir "$XDG_CONFIG_HOME"
        info_msg "Setting \$XDG_CONFIG_HOME to: '$XDG_CONFIG_HOME'"
fi

[ -n "$XAUTHORITY" ] && \
    SYS_XAUTHORITY="$XAUTHORITY"

if [[ ! -n "$XAUTHORITY" || "$SET_HOME_DIR" == 1 || \
    "$TMP_HOME" == 1 || "$TMP_HOME_DL" == 1 || \
    "$SANDBOX_HOME" == 1 || "$SANDBOX_HOME_DL" ]]
    then
        [ -n "$NEW_HOME" ] && \
        export XAUTHORITY="$NEW_HOME/.Xauthority" || \
        export XAUTHORITY="$HOME/.Xauthority"
        if [ -n "$SYS_XAUTHORITY" ]
            then
                HOME_BIND+=("--bind-try" "$SYS_XAUTHORITY" "$XAUTHORITY")
            else
                if [[ "$EUID" == 0 && "$RUNUSER" == "root" ]]
                    then
                        HOME_BIND+=("--bind-try" "/root/.Xauthority" "$XAUTHORITY")
                elif [[ "$EUID" == 0 && "$RUNUSER" != "root" ]]
                    then
                        HOME_BIND+=("--ro-bind-try" "/home/$RUNUSER/.Xauthority" "$XAUTHORITY")
                else
                    HOME_BIND+=("--bind-try" "/home/$RUNUSER/.Xauthority" "$XAUTHORITY")
                fi
        fi
fi

if [ "$UNSHARE_PIDS" == 1 ]
    then
        warn_msg "System PIDs hiding enabled!"
        UNPIDS_BIND+=("--as-pid-1" \
                        "--unshare-pid" \
                        "--bind-try" "$XDG_RUNTIME_DIR/pulse" "$XDG_RUNTIME_DIR/pulse" \
                        "--bind-try" "$XDG_RUNTIME_DIR/pipewire-0" "$XDG_RUNTIME_DIR/pipewire-0")
        [ -x "$RUNROOTFS/usr/bin/dbus-launch" ] && \
            EXEC_ARGS=("dbus-launch")
fi

if [ -d "/tmp/.X11-unix" ] # Gamecope X11 sockets bug
    then
        if [ -L "/tmp/.X11-unix" ] # WSL
            then
                TMP_BIND+=("--tmpfs" "/tmp" \
                           "--dir" "/tmp/.X11-unix")
                for i_tmp in /tmp/* /tmp/.[a-zA-Z0-9]*
                    do
                        [ "$i_tmp" != "/tmp/.X11-unix" ] && \
                            TMP_BIND+=("--bind-try" "$i_tmp" "$i_tmp")
                done
            else
                TMP_BIND+=("--bind-try" "/tmp" "/tmp" \
                           "--tmpfs" "/tmp/.X11-unix")
        fi
        if [ -n "$(ls -A /tmp/.X11-unix 2>/dev/null)" ]
            then
                for x_socket in /tmp/.X11-unix/X*
                    do
                        TMP_BIND+=("--bind-try" "$x_socket" "$x_socket")
                done
        fi
    else
        TMP_BIND+=("--bind-try" "/tmp" "/tmp")
fi

if [ -d "$TMPDIR" ]
    then
        NEWTMPDIR="/tmp/.TMPDIR"
        info_msg "Binding \$TMPDIR to: '$NEWTMPDIR'"
        TMPDIR_BIND+=("--dir" "$NEWTMPDIR" \
                      "--bind-try" "$TMPDIR" "$NEWTMPDIR" \
                      "--setenv" "TMPDIR" "$NEWTMPDIR")
    else
        unset TMPDIR
fi

[[ -n "$SANDBOX_NET_CIDR" || -n "$SANDBOX_NET_MTU" ||\
   -n "$SANDBOX_NET_TAPNAME" || -n "$SANDBOX_NET_MAC" ||\
   -f "$SANDBOX_NET_RESOLVCONF" || -f "$SANDBOX_NET_HOSTS" ]] && \
   SANDBOX_NET=1

if [[ "$SANDBOX_NET" == 1 && ! -e '/dev/net/tun' ]]
    then
        if [ "$EUID" == 0 ]
            then
                warn_msg "SANDBOX_NET enabled, but /dev/net/tun not found!"
                info_msg "Trying to create /dev/net/tun..."
                try_mkdir /dev/net
                mknod /dev/net/tun -m 0600 c 10 200
            else
                error_msg "SANDBOX_NET enabled, but /dev/net/tun not found!"
                if ! console_info_notify
                    then
                        echo -e "${YELLOW}\nYou need to create /dev/net/tun:"
                        echo -e "${RED}# ${GREEN}sudo mkdir -p /dev/net"
                        echo -e "${RED}# ${GREEN}sudo mknod /dev/net/tun -m 0600 c 10 200'$RESETCOLOR"
                fi
                FORCE_CLEANUP=1 cleanup
                exit 1
        fi
fi

if [[ "$SANDBOX_NET" == 1 || "$NO_NET" == 1 ]] && [ "$UNSHARE_PIDS" != 1 ] && \
    [[ ! -n "$DBUS_SESSION_BUS_ADDRESS" || "$DBUS_SESSION_BUS_ADDRESS" =~ "unix:abstract" ]]
    then
        DBUSD_ADDRSS="unix:path=/tmp/.rdbus.$RUNPID"
        info_msg "Launching dbus-daemon..."
        dbus-daemon --session --address="$DBUSD_ADDRSS" &>/dev/null &
        DBUSD_PID=$!
        sleep 0.05
        if [[ -n "$DBUSD_PID" && -d "/proc/$DBUSD_PID" ]]
            then
                export DBUS_SESSION_BUS_ADDRESS="$DBUSD_ADDRSS"
            else
                if which dbus-daemon &>/dev/null
                    then
                        error_msg "Failed to start dbus-daemon!"
                    else
                        error_msg "dbus-daemon not found!"
                fi
        fi
fi

if [[ "$NO_NET" == 1 || "$SANDBOX_NET" == 1 ]]
    then
        NETWORK_BIND+=("--unshare-net")
        [ "$NO_NET" == 1 ] && \
            warn_msg "Network is disabled!"
        if [ -f "$SANDBOX_NET_HOSTS" ]
            then
                info_msg "Binding '$SANDBOX_NET_HOSTS' -> '/etc/hosts'"
                NETWORK_BIND+=("--bind-try" "$SANDBOX_NET_HOSTS" "/etc/hosts")
        fi
        if [ -f "$SANDBOX_NET_RESOLVCONF" ]
            then
                info_msg "Binding '$SANDBOX_NET_RESOLVCONF' -> '/etc/resolv.conf'"
                NETWORK_BIND+=("--bind-try" "$SANDBOX_NET_RESOLVCONF" "/etc/resolv.conf")
        fi
    else
        NETWORK_BIND+=("--share-net" \
                       "--ro-bind-try" "/etc/hosts" "/etc/hosts" \
                       "--ro-bind-try" "/etc/resolv.conf" "/etc/resolv.conf")
fi

if [ "$XORG_CONF" != 0 ]
    then
        if [[ -f "$XORG_CONF" && "$(basename "$XORG_CONF")" == "xorg.conf" ]]
            then
                info_msg "Found xorg.conf in: '$XORG_CONF'"
                XORG_CONF_BIND=("--ro-bind-try" \
                                "$XORG_CONF" "/etc/X11/xorg.conf")
        elif [ -f "/etc/X11/xorg.conf" ]
            then
                info_msg "Found xorg.conf in: '/etc/X11/xorg.conf'"
                XORG_CONF_BIND=("--ro-bind-try" \
                                "/etc/X11/xorg.conf" "/etc/X11/xorg.conf")
        fi
    else
        warn_msg "Binding xorg.conf is disabled!"
fi

add_bin_pth "$HOME/.local/bin:/bin:/sbin:/usr/bin:/usr/sbin:\
/usr/lib/jvm/default/bin:/usr/local/bin:/usr/local/sbin:$SYS_PATH"
[ -n "$LD_LIBRARY_PATH" ] && \
    add_lib_pth "$LD_LIBRARY_PATH"

CUSTROOTFLST=("full" "lite" "superlite")
if [[ "${CUSTROOTFLST[@]}" =~ "$RUNROOTFSTYPE" ]]
    then
        [ -x "$RUNROOTFS/usr/bin/qt5ct" ] && \
            SETENV_ARGS+=("--setenv" "QT_QPA_PLATFORMTHEME" "qt5ct")
        [[ -x "$RUNROOTFS/usr/bin/startxfce4" && "$RUNROOTFSTYPE" != "superlite" ]] && \
            SETENV_ARGS+=("--setenv" "XDG_CURRENT_DESKTOP" "XFCE" \
                          "--setenv" "DESKTOP_SESSION" "xfce")
        if [ "$RUNROOTFSTYPE" == "superlite" ]
            then
                SETENV_ARGS+=("--setenv" "GTK_THEME" "Adwaita:dark")
                SETENV_ARGS+=("--setenv" "GTK2_RC_FILES" "/usr/share/gtk-2.0/gtkrc")
            else
                [[ -f "$RUNROOTFS/usr/share/gtk-2.0/gtkrc" && ! -f "$HOME/.config/gtk-2.0/gtkrc" && \
                ! -f "$HOME/.config/gtkrc" && ! -f "$HOME/.gtkrc-2.0" ]] && \
                    SETENV_ARGS+=("--setenv" "GTK2_RC_FILES" "/usr/share/gtk-2.0/gtkrc")
        fi
        [ -d "$RUNROOTFS/etc/zsh/zshrc" ] && \
            SETENV_ARGS+=("--setenv" "ZDOTDIR" "/etc/zsh/zshrc")
fi

if [ "$ENABLE_HOSTEXEC" == 1 ]
    then
        warn_msg "The HOSTEXEC option is enabled!"
        export EXECFL="/tmp/.exec.$RUNPID"
        ([ -n "$SYS_HOME" ] && \
            export HOME="$SYS_HOME"
        jobnum=1
        while [ -d "/proc/$RUNPID" ]
            do
                execsize=($(flock -x "$EXECFL" du -sb "$EXECFL" 2>/dev/null))
                if [[ "$execsize" -gt 0 ]]
                    then
                        execjobfl="$EXECFL.$jobnum"
                        execjoboutfl="$EXECFL.$jobnum.o"
                        jobnum=$(( $jobnum + 1 ))
                        flock -x "$EXECFL" mv -f "$EXECFL" "$execjobfl" 2>/dev/null
                        (bash "$execjobfl" &>$execjoboutfl &
                        execjobpid=$!
                        touch "$execjobfl.p.$execjobpid"
                        wait $execjobpid 2>/dev/null
                        execstat=$?
                        mv -f "$execjobfl" "$execjobfl.s.$execstat" 2>/dev/null) &
                fi
                sleep 0.05
        done; [ -n "$EXECFL" ] && rm -f "$EXECFL"* 2>/dev/null) &
fi

if [[ -f "/var/lib/dbus/machine-id" && -f "/etc/machine-id" ]]
    then MACHINEID_BIND=("--ro-bind-try" "/etc/machine-id" "/etc/machine-id" \
                         "--ro-bind-try" "/var/lib/dbus/machine-id" "/var/lib/dbus/machine-id")
elif [[ -f "/var/lib/dbus/machine-id" && ! -f "/etc/machine-id" ]]
    then MACHINEID_BIND=("--ro-bind-try" "/var/lib/dbus/machine-id" "/etc/machine-id" \
                         "--ro-bind-try" "/var/lib/dbus/machine-id" "/var/lib/dbus/machine-id")
elif [[ -f "/etc/machine-id" && ! -f "/var/lib/dbus/machine-id" ]]
    then MACHINEID_BIND=("--ro-bind-try" "/etc/machine-id" "/etc/machine-id" \
                         "--ro-bind-try" "/etc/machine-id" "/var/lib/dbus/machine-id")
fi

##############################################################################
trap 'cleanup' EXIT SIGINT SIGTERM
if [ -n "$AUTORUN" ]
    then
        [ "$1" != "$(basename "$RUNSRC")" ] && [[ "$1" == "$AUTORUN0ARG" ||\
          "$1" == "$(basename "${RUNIMAGE_CONFIG%.rcfg}")" ||\
          "$1" == "$(basename "${RUNIMAGE_INTERNAL_CONFIG%.rcfg}")" ]] && \
            shift
        if [ "${#AUTORUN[@]}" == 1 ]
            then
                bwrun /usr/bin/$AUTORUN "$@"
            else
                bwrun /usr/bin/"${AUTORUN[@]}" "$@"
        fi
    else
        if [ ! -n "$1" ]
            then
                print_help
            else
                case $1 in
                    --run-pkglist|--rP) pkg_list ;;
                    --run-kill   |--rK) force_kill ;;
                    --run-help   |--rH) print_help ;;
                    --run-binlist|--rBin) bin_list ;;
                    --run-bwhelp |--rBwh) bwrap_help ;;
                    --run-version|--rV) print_version ;;
                    --overfs-list|--oL) overlayfs_list ;;
                    --run-attach |--rA) shift ; run_attach "$@" ;;
                    --run-update |--rU) shift ; run_update "$@" ;;
                    --overfs-rm  |--oR) shift ; overlayfs_rm "$@" ;;
                    --run-desktop|--rD) bwrun /usr/bin/rundesktop ;;
                    --run-shell  |--rS) shift ; bwrun "${RUN_SHELL[@]}" "$@" ;;
                    --run-procmon|--rPm) shift ; bwrun "/usr/bin/rpidsmon" "$@" ;;
                    --run-build  |--rB) shift ; bash "$RUNROOTFS/usr/bin/runbuild" "$@" ;;
                    *) bwrun "$@" ;;
                esac
        fi
fi
exit $?
##############################################################################
