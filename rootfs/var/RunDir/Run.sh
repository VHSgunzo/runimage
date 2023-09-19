#!/usr/bin/env bash

shopt -s extglob

DEVELOPERS="VHSgunzo"
export RUNIMAGE_VERSION='0.39.1'

RED='\033[1;91m'
BLUE='\033[1;94m'
GREEN='\033[1;92m'
YELLOW='\033[1;33m'
RESETCOLOR='\033[1;00m'

[ ! -n "$SYS_PATH" ] && \
export SYS_PATH="$PATH"
export RUNPPID="$PPID"
export RUNPID="$BASHPID"
export BWINFFL="/tmp/.bwinf.$RUNPID"
export EXECFLDIR="/tmp/.exec.$RUNPID"
RPIDSFL="/tmp/.rpids.$RUNPID"
UNPASSWDFL="/tmp/.passwd.$RUNPID"
UNGROUPFL="/tmp/.group.$RUNPID"
unset RO_MNT RUNROOTFS SQFUSE BUWRAP NOT_TERM UNIONFS VAR_BIND \
      MKSQFS NVDRVMNT BWRAP_CAP NVIDIA_DRIVER_BIND EXEC_STATUS \
      SESSION_MANAGER UNSQFS TMP_BIND SYS_HOME UNSHARE_BIND \
      NETWORK_BIND SET_HOME_DIR SET_CONF_DIR HOME_BIND BWRAP_ARGS \
      LD_CACHE_BIND ADD_LD_CACHE NEW_HOME TMPDIR_BIND EXEC_ARGS \
      FUSE_PIDS XDG_RUN_BIND XORG_CONF_BIND SUID_BWRAP OVERFS_MNT \
      SET_RUNIMAGE_CONFIG SET_RUNIMAGE_INTERNAL_CONFIG OVERFS_DIR \
      RUNRUNTIME RUNSTATIC UNLIM_WAIT SETENV_ARGS SLIRP RUNDIR_BIND \
      SANDBOX_HOME_DIR MACHINEID_BIND MODULES_BIND DEF_MOUNTS_BIND

which_exe() { command -v "$@" ; }

[[ ! -n "$LANG" || "$LANG" =~ "UTF8" ]] && \
    export LANG=en_US.UTF-8

if [[ -n "$RUNOFFSET" && -n "$ARGV0" ]]
    then
        export RUNSTATIC="$RUNDIR/static"
        [ "$SYS_TOOLS" == 1 ] && \
            export PATH="$SYS_PATH:$RUNSTATIC"||\
            export PATH="$RUNSTATIC:$SYS_PATH"
        if [ ! -n "$RUNIMAGE" ] # KDE Neon, CachyOS, Puppy Linux bug
            then
                if [ -x "$(realpath "$ARGV0" 2>/dev/null)" ]
                    then
                        export RUNIMAGE="$(realpath "$ARGV0" 2>/dev/null)"
                elif [ -x "$(realpath "$(which_exe "$ARGV0")" 2>/dev/null)" ]
                    then
                        export RUNIMAGE="$(realpath "$(which_exe "$ARGV0")" 2>/dev/null)"
                else
                    export RUNIMAGE="$ARGV0"
                fi
        fi
        if [ -x "$(realpath -s "$ARGV0" 2>/dev/null)" ]
            then
                RUNSRC="$(realpath -s "$ARGV0" 2>/dev/null)"
        elif [ -x "$(realpath -s "$(which_exe "$ARGV0")" 2>/dev/null)" ]
            then
                RUNSRC="$(realpath -s "$(which_exe "$ARGV0")" 2>/dev/null)"
        else
            RUNSRC="$RUNIMAGE"
        fi
        export RUNIMAGEDIR="$(dirname "$RUNIMAGE" 2>/dev/null)"
        RUNIMAGENAME="$(basename "$RUNIMAGE" 2>/dev/null)"
    else
        [ ! -d "$RUNDIR" ] && \
            export RUNDIR="$(dirname "$(realpath "$0" 2>/dev/null)" 2>/dev/null)"
        export RUNSTATIC="$RUNDIR/static"
        [ "$SYS_TOOLS" == 1 ] && \
            export PATH="$SYS_PATH:$RUNSTATIC"||\
            export PATH="$RUNSTATIC:$SYS_PATH"
        export RUNIMAGEDIR="$(realpath "$RUNDIR/../" 2>/dev/null)"
        if [ ! -n "$RUNSRC" ]
            then
                if [ -x "$(realpath -s "$0" 2>/dev/null)" ]
                    then
                        RUNSRC="$(realpath -s "$0" 2>/dev/null)"
                elif [ -x "$(realpath -s "$(which_exe "$0")" 2>/dev/null)" ]
                    then
                        RUNSRC="$(realpath -s "$(which_exe "$0")" 2>/dev/null)"
                else
                    RUNSRC="$RUNDIR/Run"
                fi
        fi
fi

[ ! -n "$RUNTTY" ] && \
    export RUNTTY="$(tty|grep -v 'not a')"
[ ! -n "$(echo "$RUNTTY"|grep -Eo 'tty|pts')" ] && \
    NOT_TERM=1

[ "$NOT_TERM" != 1 ] && \
    SETSID_RUN=("ptyspawn")||\
    SETSID_RUN=("setsid" "--wait")

if [[ "$RUNSETSID" != 1 && ! "$RUNTTY" =~ "tty" && "$ALLOW_BG" != 1 ]]
    then
        RUNSETSID=1 "${SETSID_RUN[@]}" "$RUNSTATIC/bash" \
            "$(realpath -s "$0" 2>/dev/null)" "$@"
        exit $?
fi
unset RUNSETSID

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

nocolor() { sed -r 's|\x1B\[([0-9]{1,3}(;[0-9]{1,2};?)?)?[mGK]||g' ; }

error_msg() {
    echo -e "${RED}[ ERROR ][$(date +"%Y.%m.%d %T")]: $@ $RESETCOLOR"
    if [ "$NOT_TERM" == 1 ]
        then notify-send -a 'RunImage Error' "$(echo -e "$@"|nocolor)" 2>/dev/null &
    fi
}

info_msg() {
    if [ "$QUIET_MODE" != 1 ]
        then echo -e "${GREEN}[ INFO ][$(date +"%Y.%m.%d %T")]: $@ $RESETCOLOR"
            if [[ "$NOT_TERM" == 1 && "$DONT_NOTIFY" != 1 ]]
                then notify-send -a 'RunImage Info' "$(echo -e "$@"|nocolor)" 2>/dev/null &
            fi
    fi
}

warn_msg() {
    if [[ "$QUIET_MODE" != 1 && "$NO_WARN" != 1 ]]
        then echo -e "${YELLOW}[ WARNING ][$(date +"%Y.%m.%d %T")]: $@ $RESETCOLOR"
            if [[ "$NOT_TERM" == 1 && "$DONT_NOTIFY" != 1 ]]
                then notify-send -a 'RunImage Warning' "$(echo -e "$@"|nocolor)" 2>/dev/null &
            fi
    fi
}

console_info_notify() {
    [ "$NOT_TERM" == 1 ] && \
        notify-send -a "RunImage Info" "See the information in the console!" &
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
                            sleep 0.0001 2>/dev/null
                    fi
                else
                    return 1
            fi
    done
}

is_sys_exe() {
    [[ -x "$(which -a "$1" 2>/dev/null|grep -v "$RUNSTATIC"|head -1)" ]] && \
        return 0||return 1
}

which_sys_exe() { which -a "$1" 2>/dev/null|grep -v "$RUNSTATIC"|head -1 ; }

is_exe_exist() { command -v "$@" &>/dev/null ; }

yn_case() {
    while true
        do
            read -p "$(echo -e "${RED}$1 ${GREEN}(y/n) ${BLUE}> $RESETCOLOR")" yn
            case $yn in
                [Yy] ) return 0 ;;
                [Nn] ) return 1 ;;
            esac
    done
}

check_url_stat_code() { curl -sL -o /dev/null --insecure -I -w "%{http_code}" "$@" 2>/dev/null ; }

is_url() {
    [ ! -n "$1" ] && \
        return 1
    if [ -n "$2" ]
        then [ "$(check_url_stat_code "$1")" == "$2" ]
        else [ "$(check_url_stat_code "$1")" == "200" ]
    fi
}

try_dl() {
    err_no_downloader() {
        error_msg "Downloader not found!"
        cleanup force
        exit 1
    }
    rm_fail_dl() {
        [ -f "$FILEDIR/$FILENAME" ] && \
            rm -rf "$FILEDIR/$FILENAME" \
            "$FILEDIR/$FILENAME"*.aria2
    }
    dl_ret() {
        if [ "$1" != 0 ]
            then
                rm_fail_dl
                dl_repeat && \
                try_dl "$URL" "$FILEDIR/$FILENAME"||\
                return 1
            else return 0
        fi
    }
    dl_repeat() {
        [ "$NO_DL_REPEAT" == 1 ] && \
            return 1
        DL_REP_TITLE="Download interrupted!"
        DL_REP_TEXT="Failed to download: $FILENAME from $(echo "$URL"|awk -F/ '{print$3"/"$4}') \nWould you like to repeat it?"
        if [[ "$NOT_TERM" != 1 || "$NO_DL_GUI" == 1 ]]
            then
                yn_case "$DL_REP_TEXT"||return 1
        elif is_exe_exist yad
            then
                yad --image="dialog-error" --button="CANCEL:1" --center \
                    --button="REPEAT:0" --title="$DL_REP_TITLE" \
                    --text="$DL_REP_TEXT" --on-top --fixed
        elif is_exe_exist zenity
            then
                zenity --question --title="$DL_REP_TITLE" --no-wrap \
                    --text="$DL_REP_TEXT"
        else return 1
        fi
    }
    if [ -n "$1" ]
        then
            URL="$1"
            if [ -n "$2" ]
                then
                    if [ -d "$2" ]
                        then
                            FILEDIR="$2"
                            FILENAME="$(basename "$1")"
                        else
                            FILEDIR="$(dirname "$2")"
                            FILENAME="$(basename "$2")"
                    fi
                else
                    FILEDIR="."
                    FILENAME="$(basename "$1")"
            fi
            if is_url "$URL"
                then
                    [ ! -d "$FILEDIR" ] && \
                        try_mkdir "$FILEDIR"
                    if [[ "$NOT_TERM" == 1 && "$NO_DL_GUI" != 1 ]] && \
                        (is_exe_exist yad||is_exe_exist zenity)
                        then
                            set -o pipefail
                            dl_progress() {
                                [[ "$URL" =~ '&key=' ]] && \
                                    local URL="$(echo "$URL"|sed "s|\&key=.*||g")"
                                [[ "$URL" =~ '&' && ! "$URL" =~ '&amp;' ]] && \
                                    local URL="$(echo "$URL"|sed "s|\&|\&amp;|g")"
                                if is_exe_exist yad
                                    then
                                        yad --progress --percentage=0 --text="Download:\t$FILENAME\n$URL" \
                                            --auto-close --no-escape --selectable-labels --auto-kill \
                                            --center --on-top --fixed --no-buttons --undecorated --skip-taskbar
                                elif is_exe_exist zenity
                                    then
                                        zenity --progress --text="Connecting to $URL" --width=650 --height=40 \
                                            --auto-close --no-cancel --title="Download: $FILENAME"
                                else return 1
                                fi
                            }
                            if [ "$NO_ARIA2C" != 1 ] && \
                                is_exe_exist aria2c
                                then
                                    aria2c -R -x 13 -s 13 --allow-overwrite --summary-interval=1 -o \
                                        "$FILENAME" -d "$FILEDIR" "$URL"|grep --line-buffered 'ETA'|\
                                        sed -u 's|(.*)| &|g;s|(||g;s|)||g;s|\[||g;s|\]||g'|\
                                        awk '{print$3"\n#Downloading at "$3,$2,$5,$6;system("")}'|\
                                    dl_progress
                            elif is_exe_exist wget
                                then
                                    wget --no-check-certificate --content-disposition -t 3 -T 5 \
                                        -w 0.5 "$URL" -O "$FILEDIR/$FILENAME"|& tr '\r' '\n'|\
                                        sed -u 's/.* \([0-9]\+%\)\ \+\([0-9,.]\+.\) \(.*\)/\1\n#Downloading at \1\ ETA: \3/; s/^20[0-9][0-9].*/#Done./'|\
                                    dl_progress
                            elif is_exe_exist curl
                                then
                                    curl -R --progress-bar --insecure --fail -L "$URL" -o \
                                        "$FILEDIR/$FILENAME" |& tr '\r' '\n'|\
                                        sed -ur 's|[# ]+||g;s|.*=.*||g;s|.*|#Downloading at &\n&|g'|\
                                    dl_progress
                            else
                                err_no_downloader
                            fi
                            dl_ret "${PIPESTATUS[0]}"||return 1
                        else
                            if [ "$NO_ARIA2C" != 1 ] && is_exe_exist aria2c
                                then
                                    aria2c -R -x 13 -s 13 --allow-overwrite -d "$FILEDIR" -o "$FILENAME" "$URL"
                            elif is_exe_exist wget
                                then
                                    wget -q --show-progress --no-check-certificate --content-disposition \
                                        -t 3 -T 5 -w 0.5 "$URL" -O "$FILEDIR/$FILENAME"
                            elif is_exe_exist curl
                                then
                                    curl -R --progress-bar --insecure --fail -L "$URL" -o "$FILEDIR/$FILENAME"
                            else
                                err_no_downloader
                            fi
                            dl_ret "$?"||return 1
                    fi
                else
                    error_msg "$FILENAME not found in $(echo "$URL"|awk -F/ '{print$3"/"$4}')"
                    return 1
            fi
        else
            error_msg "Specify download URL!"
            return 1
    fi
}

get_nvidia_driver_image() {
    (if [[ -n "$1" || -n "$nvidia_version" ]]
        then
            [ ! -n "$nvidia_version" ] && \
                nvidia_version="$1"
            [[ -d "$2" && ! -n "$NVIDIA_DRIVERS_DIR" ]] && \
                export NVIDIA_DRIVERS_DIR="$2"
            [[ ! -d "$2" && ! -n "$NVIDIA_DRIVERS_DIR" ]] && \
                export NVIDIA_DRIVERS_DIR="."
            [ ! -n "$nvidia_driver_image" ] && \
                nvidia_driver_image="$nvidia_version.nv.drv"
            try_mkdir "$NVIDIA_DRIVERS_DIR"
            info_msg "Downloading Nvidia ${nvidia_version} driver, please wait..."
            nvidia_driver_run="NVIDIA-Linux-x86_64-${nvidia_version}.run"
            driver_url_list=(
                "https://huggingface.co/runimage/nvidia-drivers/resolve/main/releases/$nvidia_driver_image"
                "https://github.com/VHSgunzo/runimage-nvidia-drivers/releases/download/v${nvidia_version}/$nvidia_driver_image"
                "https://us.download.nvidia.com/XFree86/Linux-x86_64/${nvidia_version}/$nvidia_driver_run"
                "https://us.download.nvidia.com/tesla/${nvidia_version}/$nvidia_driver_run"
            )
            if try_dl "${driver_url_list[0]}" "$NVIDIA_DRIVERS_DIR"||\
               try_dl "${driver_url_list[1]}" "$NVIDIA_DRIVERS_DIR"
                then return 0
            elif try_dl "${driver_url_list[2]}" "$NVIDIA_DRIVERS_DIR"||\
                 try_dl "${driver_url_list[3]}" "$NVIDIA_DRIVERS_DIR"
                then
                    binary_files="mkprecompiled nvidia-cuda-mps-control nvidia-cuda-mps-server \
                        nvidia-debugdump nvidia-installer nvidia-modprobe nvidia-ngx-updater tls_test \
                        nvidia-persistenced nvidia-powerd nvidia-settings nvidia-smi nvidia-xconfig"
                    trash_libs="libEGL.so* libGLdispatch.so* *.swidtag libnvidia-egl-wayland.so* \
                         libGLESv!(*nvidia).so* libGL.so* libGLX.so* libOpenCL.so* libOpenGL.so* \
                         libnvidia-compiler* *.la"
                    chmod u+x "$NVIDIA_DRIVERS_DIR/$nvidia_driver_run"
                    info_msg "Unpacking $nvidia_driver_run..."
                    (cd "$NVIDIA_DRIVERS_DIR" && \
                        "./$nvidia_driver_run" --target "$nvidia_version" -x &>/dev/null
                        rm -f "$nvidia_driver_run")
                    info_msg "Creating a driver directory structure..."
                    (cd "$NVIDIA_DRIVERS_DIR/$nvidia_version" && \
                        rm -rf html kernel* libglvnd_install_checker 32/libglvnd_install_checker \
                            supported-gpus systemd *.gz *.bz2 *.txt .manifest *.desktop *.png firmware *.h
                        for temp in $(ls *.template 2>/dev/null) ; do mv "$temp" "${temp%.template}" ; done
                        try_mkdir profiles && mv *application-profiles* profiles
                        [ -f "nvoptix.bin" ] && mv nvoptix.bin profiles
                        [ -n "$(ls *nvngx.dll 2>/dev/null)" ] && try_mkdir wine && mv *nvngx.dll wine
                        try_mkdir json && mv *.json json
                        try_mkdir conf && mv *.conf *.icd conf
                        for lib in $trash_libs ; do rm -f $lib 32/$lib ; done
                        try_mkdir bin && mv *.sh bin
                        for binary in $binary_files ; do [ -f "$binary" ] && mv $binary bin ; done
                        try_mkdir 64 && mv *.so* 64
                        [ -d "tls" ] && mv tls/* 64 && rm -rf tls
                        [ -d "32/tls" ] && mv 32/tls/* 32 && rm -rf 32/tls)
                    info_msg "Creating a squashfs driver image..."
                    info_msg "$NVIDIA_DRIVERS_DIR/$nvidia_driver_image"
                    echo -en "$BLUE"
                    if "$MKSQFS" "$NVIDIA_DRIVERS_DIR/$nvidia_version" "$NVIDIA_DRIVERS_DIR/$nvidia_driver_image" \
                        -root-owned -no-xattrs -noappend -b 1M -comp zstd -Xcompression-level 19 -quiet
                        then
                            info_msg "Deleting the source directory of the driver..."
                            rm -rf "$NVIDIA_DRIVERS_DIR/$nvidia_version"
                            return 0
                        else
                            return 1
                    fi
                    echo -en "$RESETCOLOR"
                else
                    error_msg "Failed to download nvidia driver!"
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
            "$SQFUSE" -f "$1" "$NVDRVMNT" -o ro &>/dev/null &
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
                if (ALLOW_BG=0 SANDBOX_NET=0 bwrun /usr/bin/ldconfig -C "/tmp/ld.so.cache" 2>/dev/null)
                    then
                        try_mkdir "$RUNCACHEDIR"
                        if mv -f "/tmp/ld.so.cache" \
                            "$RUNCACHEDIR/ld.so.cache" 2>/dev/null
                            then
                                echo "$RUNROOTFS_VERSION-$nvidia_version" > \
                                    "$RUNCACHEDIR/ld.so.version"
                                if [ -w "$RUNROOTFS" ]
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
                if [ -w "$RUNROOTFS" ]
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
    if [ -e '/sys/module/nvidia/version' ]||\
        grep -owm1 nvidia /proc/modules &>/dev/null
        then
            unset nvidia_driver_dir
            [ ! -n "$NVIDIA_DRIVERS_DIR" ] && \
                export NVIDIA_DRIVERS_DIR="$RUNIMAGEDIR/nvidia-drivers"
            if [ -e '/sys/module/nvidia/version' ]
                then
                    nvidia_version="$(cat /sys/module/nvidia/version 2>/dev/null)"
            elif modinfo nvidia &>/dev/null
                then
                    nvidia_version="$(modinfo -F version nvidia 2>/dev/null)"
            elif nvidia-smi &>/dev/null
                then
                    nvidia_version="$(nvidia-smi --query-gpu=driver_version --format=csv,noheader|head -1)"
            else
                if [ -d '/usr/lib/x86_64-linux-gnu' ]
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
                                    if [ ! -f "$NVIDIA_DRIVERS_DIR/$nvidia_version/64/nvidia_drv.so" ] && \
                                        [ ! -f "$RUNIMAGEDIR/$nvidia_driver_image" ] && \
                                        [ ! -f "$NVIDIA_DRIVERS_DIR/$nvidia_driver_image" ] && \
                                        [ ! -f "$NVDRVMNT/64/nvidia_drv.so" ] && \
                                        [ ! -f "$RUNDIR/nvidia-drivers/$nvidia_version/64/nvidia_drv.so" ] && \
                                        [ ! -f "$RUNDIR/nvidia-drivers/$nvidia_driver_image" ]
                                        then
                                            if DONT_NOTIFY=0 QUIET_MODE=0 get_nvidia_driver_image
                                                then
                                                    mount_nvidia_driver_image "$NVIDIA_DRIVERS_DIR/$nvidia_driver_image"
                                                else
                                                    nvidia_driver_dir="$NVIDIA_DRIVERS_DIR/$nvidia_version"
                                            fi
                                        else
                                            if [ -f "$NVDRVMNT/64/nvidia_drv.so" ]
                                                then
                                                    nvidia_driver_dir="$NVDRVMNT"
                                                    print_nv_drv_dir
                                            elif [ -f "$NVIDIA_DRIVERS_DIR/$nvidia_version/64/nvidia_drv.so" ]
                                                then
                                                    nvidia_driver_dir="$NVIDIA_DRIVERS_DIR/$nvidia_version"
                                                    print_nv_drv_dir
                                            elif [ -f "$RUNIMAGEDIR/$nvidia_driver_image" ]
                                                then
                                                    mount_nvidia_driver_image "$RUNIMAGEDIR/$nvidia_driver_image"
                                            elif [ -f "$NVIDIA_DRIVERS_DIR/$nvidia_driver_image" ]
                                                then
                                                    mount_nvidia_driver_image "$NVIDIA_DRIVERS_DIR/$nvidia_driver_image"
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
                                    nvidia_libs_list="libcuda.so libEGL_nvidia.so libGLESv1_CM_nvidia.so libnvidia-opencl.so \
                                        libGLESv2_nvidia.so libGLX_nvidia.so libnvcuvid.so libnvidia-allocator.so \
                                        libnvidia-cfg.so libnvidia-eglcore.so libnvidia-encode.so libnvidia-fbc.so \
                                        libnvidia-glcore.so libnvidia-glsi.so libnvidia-glvkspirv.so libnvidia-ml.so \
                                        libnvidia-ngx.so libnvidia-opticalflow.so libnvidia-ptxjitcompiler.so libcudadebugger.so \
                                        libnvidia-rtcore.so libnvidia-tls.so libnvidia-vulkan-producer.so libnvoptix.so \
                                        libnvidia-nvvm.so libnvidia-pkcs11.so libnvidia-pkcs11-openssl3.so libnvidia-wayland-client.so"
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
                                    if [ -f "$RUNROOTFS/usr/lib/libnvidia-api.so.1" ]
                                        then
                                            NVIDIA_DRIVER_BIND+=("--ro-bind-try" \
                                                "$nvidia_driver_dir/64/libnvidia-api.so.1" \
                                                "/usr/lib/libnvidia-api.so.1")
                                    fi
                                    if [ -f "$RUNROOTFS/usr/lib/libnvidia-egl-gbm.so.1.1.0" ]
                                        then
                                            NVIDIA_DRIVER_BIND+=("--ro-bind-try" \
                                                "$nvidia_driver_dir/64/libnvidia-egl-gbm.so.1.1.0" \
                                                "/usr/lib/libnvidia-egl-gbm.so.1.1.0")
                                    fi
                                    if [ -f "$RUNROOTFS/usr/lib/xorg/modules/drivers/nvidia_drv.so" ]
                                        then
                                            NVIDIA_DRIVER_BIND+=("--ro-bind-try" \
                                                "$nvidia_driver_dir/64/nvidia_drv.so" \
                                                "/usr/lib/xorg/modules/drivers/nvidia_drv.so")
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
                                    if [ -f "$RUNROOTFS/etc/OpenCL/vendors/nvidia.icd" ]
                                        then
                                            NVIDIA_DRIVER_BIND+=("--ro-bind-try" \
                                                "$nvidia_driver_dir/conf/nvidia.icd" \
                                                "/etc/OpenCL/vendors/nvidia.icd")
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
                                    if [ -w "$RUNROOTFS" ]
                                        then
                                            if [[ ! -d "$RUNROOTFS/usr/bin/nvidia" || \
                                                  ! -d "$RUNROOTFS/usr/lib/nvidia/64" || \
                                                  ! -d "$RUNROOTFS/usr/lib/nvidia/32" ]]
                                                then
                                                    mkdir -p "$RUNROOTFS/usr/bin/nvidia"
                                                    mkdir -p "$RUNROOTFS/usr/lib/nvidia/64"
                                                    mkdir -p "$RUNROOTFS/usr/lib/nvidia/32"
                                            fi
                                            if [ ! -f "$RUNROOTFS/etc/ld.so.conf.d/nvidia.conf" ]
                                                then
                                                    mkdir -p "$RUNROOTFS/etc/ld.so.conf.d"
                                                    echo -e "/usr/lib/nvidia/64\n/usr/lib/nvidia/32" > \
                                                        "$RUNROOTFS/etc/ld.so.conf.d/nvidia.conf"
                                                    rm -f "$RUNCACHEDIR/ld.so."*
                                            fi
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
                                    elif [ -d "$nvidia_driver_dir/bin" ] && \
                                         [ -d "$nvidia_driver_dir/64" ] && \
                                         [ -d "$nvidia_driver_dir/32" ]
                                        then
                                            add_bin_pth "$nvidia_driver_dir/bin"
                                            add_lib_pth "$nvidia_driver_dir/64:$nvidia_driver_dir/32"
                                    fi
                                    update_ld_cache
                                    NVXSOCKET="$(ls /run/nvidia-xdriver-* 2>/dev/null|head -1)"
                                    [ -S "$NVXSOCKET" ] && \
                                        XDG_RUN_BIND+=("--bind-try" "$NVXSOCKET" "$NVXSOCKET")
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
    if [ -n "$1" ]
        then
            unset DORM
            if [ -n "$(grep -o "$1" /proc/self/mounts 2>/dev/null)" ]
                then
                    if fusermount -uz "$1" 2>/dev/null
                        then DORM=1
                    elif umount -l "$1" 2>/dev/null
                        then DORM=1
                    elif [ "$ALLOW_BG" != 1 ] && \
                        kill -2 $FUSE_PIDS 2>/dev/null
                        then DORM=1
                    else
                        error_msg "Failed to unmount: '$1'"
                        return 1
                    fi
            elif [ -d "$1" ]
                then DORM=1
            fi
            if [ "$DORM" == 1 ]
                then
                    if ! rm -rf "$1" 2>/dev/null
                        then
                            error_msg "Failed to remove: '$1'"
                            return 1
                    fi
            fi
            return 0
    fi
    return 1
}

try_mkdir() {
    if [ ! -d "$1" ]
        then
            if ! mkdir -p "$1"
                then
                    error_msg "Failed to create directory: '$1'"
                    cleanup force
                    exit 1
            fi
    fi
}

run_attach() {
    set_target() {
        unset NSU
        [ "$EUID" != 0 ] && NSU="-U"
        for pid in $(cat "/tmp/.rpids.$1")
            do
                for args in "-n -p" "-n" "-p" " "
                    do
                        if nsenter --preserve-credentials $NSU -m $args \
                            -t $pid /usr/bin/true &>/dev/null
                            then
                                target="$pid"
                                target_args="$args"
                                return 0
                        fi
                done
        done
        return 1
    }
    ns_attach() {
        unset WAITRPIDS
        if set_target "$1"
            then
                info_msg "Attaching to RunImage RUNPID: $1"
                (while [[ -d "/proc/$target" && -d "/proc/$RUNPID" ]]
                    do sleep 0.5 2>/dev/null
                done
                cleanup force) &
                shift
                if [[ "$ALLOW_BG" == 1 || "$RUNTTY" =~ "tty" ]]
                    then
                        (wait_rpids=100
                        while [[ "$wait_rpids" -gt 0 && ! -n "$(ps -o pid= -p \
                            $(cat "$RPIDSFL" 2>/dev/null) 2>/dev/null)" ]]
                            do
                                wait_rpids="$(( $wait_rpids - 1 ))"
                                sleep 0.01 2>/dev/null
                        done; sleep 1) &
                        WAITRPIDS=$!
                fi
                importenv $target nsenter --preserve-credentials \
                    --wd=/proc/$target/cwd $NSU -m $target_args -t $target "$@"
                EXEC_STATUS=$?
                [ -n "$WAITRPIDS" ] && \
                    wait "$WAITRPIDS"
                return $EXEC_STATUS
        fi
        error_msg "Failed to attach to RunImage container!"
        return 1
    }
    if [[ "$1" =~ ^[0-9]+$ ]]
        then
            if [ -f "/tmp/.rpids.$1" ]
                then
                    if [ -n "$2" ]
                        then ns_attach "$@"
                        else ns_attach "$@" "${RUN_SHELL[@]}"
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
                        then ns_attach "$runpid" "$@"
                        else ns_attach "$runpid" "${RUN_SHELL[@]}"
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
                   echo "$RUNIMAGENAME"||echo "$RUNIMAGEDIR")|/tmp/.mount_nv.*drv|unionfs.*$RUNIMAGEDIR" \
                    /proc/self/mounts|grep -v "$RUNDIR"|awk '{print$2}')"
    if [ -n "$MOUNTPOINTS" ]
        then
            (IFS=$'\n' ; for umnt in $MOUNTPOINTS
                do try_unmount "$umnt"
            done) && SUCCUMNT=1
    fi
    try_kill "$(cat /tmp/.rpids.* 2>/dev/null)" && \
        SUCCKILL=1
    [[ "$SUCCKILL" == 1 || "$SUCCUMNT" == 1 ]] && \
        info_msg "RunImage successfully killed!"
}

try_kill() {
    ret=1
    if [ -n "$1" ]
        then
            for pid in $1
                do
                    trykillnum=0
                    while [[ -n "$pid" && -d "/proc/$pid" ]]
                        do
                            if [[ "$trykillnum" -lt 1 ]]
                                then
                                    kill -2 $pid 2>/dev/null
                                    ret=$?
                                    sleep 0.05 2>/dev/null
                            elif [[ "$trykillnum" -lt 2 ]]
                                then
                                    kill -15 $pid 2>/dev/null
                                    ret=$?
                                    sleep 0.05 2>/dev/null
                            else
                                kill -9 $pid 2>/dev/null
                                ret=$?
                                break
                            fi
                            trykillnum="$(( $trykillnum + 1 ))"
                    done
            done
    fi
    return $ret
}

cleanup() {
    if [[ "$NO_CLEANUP" != 1 || "$1" == "force" ]]
        then
            [ "$1" == "force" ] && \
                QUIET_MODE=1
            if [ -n "$FUSE_PIDS" ]
                then
                    [[ "$ALLOW_BG" != 1 && "$KEEP_OVERFS" != 1 ]] && \
                        try_unmount "$OVERFS_MNT"
                    [[ "$ALLOW_BG" == 1 && -d "$OVERFS_MNT" ]] ||\
                        try_unmount "$RO_MNT"
                    try_unmount "$NVDRVMNT"
            fi
            [ -d "$EXECFLDIR" ] && \
                rm -rf "$EXECFLDIR" 2>/dev/null
            if [[ "$ALLOW_BG" != 1 || "$1" == "force" ]]
                then
                    kill -2 $FUSE_PIDS 2>/dev/null
                    if [ -n "$DBUSP_PID" ]
                        then
                            kill $DBUSP_PID 2>/dev/null
                            [ -S "$DBUSP_SOCKET" ] && \
                                rm -f "$DBUSP_SOCKET" 2>/dev/null
                    fi
                    try_kill "$(cat "$RPIDSFL" 2>/dev/null)"
                    if [[ -d "$OVERFS_DIR" && "$KEEP_OVERFS" != 1 ]]
                        then
                            info_msg "Removing OverlayFS..."
                            rm -rf "$OVERFS_DIR" 2>/dev/null
                    fi
            fi
            [ -f "$RPIDSFL" ] && \
                rm -f "$RPIDSFL" 2>/dev/null
            [ -f "$BWINFFL" ] && \
                rm -f "$BWINFFL" 2>/dev/null
            [ -f "$UNPASSWDFL" ] && \
                rm -f "$UNPASSWDFL" 2>/dev/null
            [ -f "$UNGROUPFL" ] && \
                rm -f "$UNGROUPFL" 2>/dev/null
        else
            warn_msg "Cleanup is disabled!"
    fi
}

get_child_pids() {
    if [[ -n "$1" && -d "/proc/$1" ]]
        then
            local child_pids="$(ps --forest -o pid= -g $(ps -o sid= -p $1 2>/dev/null) 2>/dev/null)"
            ps -o user=,pid=,cmd= -p $child_pids 2>/dev/null|grep "^$RUNUSER"|\
            grep -v "bash $RUNDIR/Run.sh"|grep -Pv '\d+ sleep \d+'|\
            grep -wv "$RUNPPID"|awk '{print$2}'|sort -nu
        else
            return 1
    fi
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
            unset SLEEP_EXEC
            [ "$ALLOW_BG" == 1 ] && \
                SLEEP_EXEC=("/usr/bin/sleep-exec" "0.05")
            (while [[ -d "/proc/$RUNPID" && ! -f "$BWINFFL" ]]
                do sleep 0.01 2>/dev/null
            done
            unset bwchildpid
            while [[ -d "/proc/$RUNPID" && -f "$BWINFFL" && \
                ! -n "$bwchildpid" ]] && ! kill -0 "$bwchildpid" 2>/dev/null
                do
                    bwchildpid="$(grep 'child-pid' "$BWINFFL" 2>/dev/null|grep -Po '\d+')"
                    sleep 0.01 2>/dev/null
            done
            info_msg "Creating a network sandbox..."
            "$SLIRP" --configure \
                $([ "$SANDBOX_NET_SHARE_HOST" == 1 ] || echo "--disable-host-loopback")  \
                $([ -n "$SANDBOX_NET_CIDR" ] && echo "--cidr=$SANDBOX_NET_CIDR") \
                $([ -n "$SANDBOX_NET_MTU" ] && echo "--mtu=$SANDBOX_NET_MTU") \
                $([ -n "$SANDBOX_NET_MAC" ] && echo "--macaddress=$SANDBOX_NET_MAC") \
                "$bwchildpid" \
                $([ -n "$SANDBOX_NET_TAPNAME" ] && echo "$SANDBOX_NET_TAPNAME"||echo 'eth0') &
            SLIRP_PID=$!
            sleep 0.2
            if [[ -n "$SLIRP_PID" && -d "/proc/$SLIRP_PID" ]]
                then
                    if [ "$ALLOW_BG" != 1 ]
                        then
                            while [[ -d "/proc/$RUNPID" && -f "$BWINFFL" ]]
                                do sleep 0.5 2>/dev/null
                            done
                            try_kill "$SLIRP_PID"
                    fi
                else
                    error_msg "Failed to create a network sandbox!"
                    sleep 1
                    cleanup force
                    exit 1
            fi) &
            sleep 0.05
    fi
    if [[ "$ALLOW_BG" == 1 || "$RUNTTY" =~ "tty" ]]
        then
            (wait_bwrap=100
            while [[ "$wait_bwrap" -gt 0 && ! -f "$BWINFFL" ]]
                do
                    wait_bwrap="$(( $wait_bwrap - 1 ))"
                    sleep 0.01 2>/dev/null
            done; sleep 1) &
            WAITBWPID=$!
    fi
    "$BUWRAP" --bind-try "$RUNROOTFS" / \
        --info-fd 8 \
        --proc /proc \
        --bind-try /sys /sys \
        --dev-bind-try /dev /dev \
        --ro-bind-try /etc/hostname /etc/hostname \
        --ro-bind-try /etc/localtime /etc/localtime \
        --ro-bind-try /etc/nsswitch.conf /etc/nsswitch.conf \
        "${MODULES_BIND[@]}" "${DEF_MOUNTS_BIND[@]}" \
        "${USERS_BIND[@]}" "${RUNDIR_BIND[@]}" \
        "${VAR_BIND[@]}" "${MACHINEID_BIND[@]}" \
        "${NVIDIA_DRIVER_BIND[@]}" "${TMP_BIND[@]}" \
        "${NETWORK_BIND[@]}" "${XDG_RUN_BIND[@]}" \
        "${LD_CACHE_BIND[@]}" "${TMPDIR_BIND[@]}" \
        "${UNSHARE_BIND[@]}" "${HOME_BIND[@]}" \
        "${XORG_CONF_BIND[@]}" "${BWRAP_CAP[@]}" \
        --setenv INSIDE_RUNIMAGE '1' \
        --setenv RUNPID "$RUNPID" \
        --setenv PATH "$BIN_PATH" \
        --setenv FAKEROOTDONTTRYCHOWN "true" \
        --setenv LD_LIBRARY_PATH "$LIB_PATH" \
        --setenv XDG_CONFIG_DIRS "/etc/xdg:$XDG_CONFIG_DIRS" \
        --setenv XDG_DATA_DIRS "/usr/local/share:/usr/share:$XDG_DATA_DIRS" \
        "${SETENV_ARGS[@]}" "${BWRAP_ARGS[@]}" \
        "${EXEC_ARGS[@]}" "${SLEEP_EXEC[@]}" \
        "$@" 8>$BWINFFL
    EXEC_STATUS=$?
    [ -n "$WAITBWPID" ] && \
        wait "$WAITBWPID"
    [ -f "$BWINFFL" ] && \
        rm -f "$BWINFFL"
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
    info_msg "RunImage update"
    NO_NVIDIA_CHECK=1 QUIET_MODE=1 ALLOW_BG=0 \
        bwrun /usr/bin/runupdate
    UPDATE_STATUS="$?"
    if [ "$UPDATE_STATUS" == 0 ]
        then
            if [ -n "$(ls -A "$RUNROOTFS/var/cache/pacman/pkg/" 2>/dev/null)" ]
                then
                    if [ -n "$RUNIMAGE" ]
                        then
                            (cd "$RUNIMAGEDIR" && \
                            run_build "$@")
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

add_unshared_user() {
    if grep -o ".*:x:$EUID:" "$1" &>/dev/null
        then sed -i "s|.*:x:$EUID:.*|$RUNUSER:x:$EUID:0:[^_^]:/home/$RUNUSER:/usr/bin/bash|g" "$1"
        else echo "$RUNUSER:x:$EUID:0:[^_^]:/home/$RUNUSER:/usr/bin/bash" >> "$1"
    fi
}

run_build() { "$RUNSTATIC/bash" "$RUNROOTFS/usr/bin/runbuild" "$@" ; }

set_default_option() {
    NO_WARN=1
    ALLOW_BG=0
    XORG_CONF=0
    SANDBOX_NET=0
    SQFUSE_REMOUNT=0
    NO_NVIDIA_CHECK=1
    ENABLE_HOSTEXEC=0
}

print_help() {
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
        ${YELLOW}SANDBOX_HOME_DIR$GREEN=\"/path/dir\"         Specifies sandbox home directory and bind it to /home/${YELLOW}\$USER${GREEN} or to /root
        ${YELLOW}PORTABLE_HOME$GREEN=1                      Creates a portable home directory and uses it as ${YELLOW}\$HOME
        ${YELLOW}PORTABLE_HOME_DIR$GREEN=\"/path/dir\"        Specifies a portable home directory and uses it as ${YELLOW}\$HOME
        ${YELLOW}PORTABLE_CONFIG$GREEN=1                    Creates a portable config directory and uses it as ${YELLOW}\$XDG_CONFIG_HOME
        ${YELLOW}NO_CLEANUP$GREEN=1                         Disables unmounting and cleanup mountpoints
        ${YELLOW}ALLOW_BG$GREEN=1                           Allows you to run processes in the background
        ${YELLOW}UNSHARE_PIDS$GREEN=1                       Unshares all host processes
        ${YELLOW}UNSHARE_USERS$GREEN=1                      Don't bind-mount /etc/{passwd,group}
        ${YELLOW}SHARE_SYSTEMD$GREEN=1                      Shares SystemD from the host
        ${YELLOW}UNSHARE_DBUS$GREEN=1                       Unshares DBUS from the host
        ${YELLOW}UNSHARE_UDEV$GREEN=1                       Unshares UDEV from the host (/run/udev)
        ${YELLOW}UNSHARE_MODULES$GREEN=1                    Unshares kernel modules from the host (/usr/lib/modules)
        ${YELLOW}UNSHARE_DEF_MOUNTS$GREEN=1                 Unshares default mount points (/mnt /media /run/media)
        ${YELLOW}NO_NVIDIA_CHECK$GREEN=1                    Disables checking the nvidia driver version
        ${YELLOW}NVIDIA_DRIVERS_DIR$GREEN=\"/path/dir\"       Specifies custom Nvidia driver images directory
        ${YELLOW}RUNCACHEDIR$GREEN=\"/path/dir\"              Specifies custom runimage cache directory
        ${YELLOW}SQFUSE_REMOUNT$GREEN=1                     Remounts the container using squashfuse (fix MangoHud and VkBasalt bug)
        ${YELLOW}OVERFS_MODE$GREEN=1                        Enables OverlayFS mode
        ${YELLOW}KEEP_OVERFS$GREEN=1                        Enables OverlayFS mode with saving after closing runimage
        ${YELLOW}OVERFS_ID$GREEN=ID                         Specifies the OverlayFS ID
        ${YELLOW}KEEP_OLD_BUILD$GREEN=1                     Creates a backup of the old RunImage when building a new one
        ${YELLOW}BUILD_WITH_EXTENSION$GREEN=1               Adds an extension when building (compression method and rootfs type)
        ${YELLOW}CMPRS_ALGO$GREEN={zstd|xz|lz4}             Specifies the compression algo for runimage build
        ${YELLOW}ZSDT_CMPRS_LVL$GREEN={1-19}                Specifies the compression ratio of the zstd algo for runimage build
        ${YELLOW}NO_RUNDIR_BIND$GREEN=1                     Disables binding RunDir to /var/RunDir
        ${YELLOW}RUN_SHELL$GREEN=\"shell\"                    Selects ${YELLOW}\$SHELL$GREEN in runimage
        ${YELLOW}NO_CAP$GREEN=1                             Disables Bubblewrap capabilities (Default: ALL, drop CAP_SYS_NICE)
                                                you can also use /usr/bin/nocap in runimage
        ${YELLOW}AUTORUN$GREEN=\"{executable} {args}\"        Run runimage with autorun options for /usr/bin executables
        ${YELLOW}ALLOW_ROOT$GREEN=1                         Allows to run runimage under root user
        ${YELLOW}QUIET_MODE$GREEN=1                         Disables all non-error runimage messages
        ${YELLOW}NO_WARN$GREEN=1                            Disables all warning runimage messages
        ${YELLOW}DONT_NOTIFY$GREEN=1                        Disables all non-error runimage notification
        ${YELLOW}RUNTIME_EXTRACT_AND_RUN$GREEN=1            Run runimage afer extraction without using FUSE
        ${YELLOW}TMPDIR$GREEN=\"/path/{TMPDIR}\"              Used for extract and run options
        ${YELLOW}RUNIMAGE_CONFIG$GREEN=\"/path/{config}\"     runimage сonfiguration file (0 to disable)
        ${YELLOW}ENABLE_HOSTEXEC$GREEN=1                    Enables the ability to execute commands at the host level
        ${YELLOW}NO_RPIDSMON$GREEN=1                        Disables the monitoring thread of running processes
        ${YELLOW}SANDBOX_NET$GREEN=1                        Creates a network sandbox
        ${YELLOW}SANDBOX_NET_SHARE_HOST$GREEN=1             Creates a network sandbox with access to host loopback
        ${YELLOW}SANDBOX_NET_CIDR$GREEN=11.22.33.0/24       Specifies tap interface subnet in network sandbox (Def: 10.0.2.0/24)
        ${YELLOW}SANDBOX_NET_TAPNAME$GREEN=tap0             Specifies tap interface name in network sandbox (Def: eth0)
        ${YELLOW}SANDBOX_NET_MAC$GREEN=B6:40:E0:8B:A6:D7    Specifies tap interface MAC in network sandbox (Def: random)
        ${YELLOW}SANDBOX_NET_MTU$GREEN=65520                Specifies tap interface MTU in network sandbox (Def: 1500)
        ${YELLOW}SANDBOX_NET_HOSTS$GREEN=\"file\"             Binds specified file to /etc/hosts in network sandbox
        ${YELLOW}SANDBOX_NET_RESOLVCONF$GREEN=\"file\"        Binds specified file to /etc/resolv.conf in network sandbox
        ${YELLOW}BWRAP_ARGS$GREEN+=()                       Array with Bubblewrap arguments (for config file)
        ${YELLOW}EXEC_ARGS$GREEN+=()                        Array with Bubblewrap exec arguments (for config file)
        ${YELLOW}XORG_CONF$GREEN=\"/path/xorg.conf\"          Binds xorg.conf to /etc/X11/xorg.conf in runimage (0 to disable)
                                                (Default: /etc/X11/xorg.conf bind from the system)
        ${YELLOW}XEPHYR_SIZE$GREEN=\"HEIGHTxWIDTH\"           Sets runimage desktop resolution (Default: 1600x900)
        ${YELLOW}XEPHYR_DISPLAY$GREEN=\":9999\"               Sets runimage desktop ${YELLOW}\$DISPLAY$GREEN (Default: :1337)
        ${YELLOW}XEPHYR_FULLSCREEN$GREEN=1                  Starts runimage desktop in full screen mode
        ${YELLOW}UNSHARE_CLIPBOARD$GREEN=1                  Disables clipboard synchronization for runimage desktop

        ${YELLOW}SYS_BUWRAP$GREEN=1                         Using system ${BLUE}bwrap
        ${YELLOW}SYS_SQFUSE$GREEN=1                         Using system ${BLUE}squashfuse
        ${YELLOW}SYS_UNSQFS$GREEN=1                         Using system ${BLUE}unsquashfs
        ${YELLOW}SYS_MKSQFS$GREEN=1                         Using system ${BLUE}mksquashfs
        ${YELLOW}SYS_UNIONFS$GREEN=1                        Using system ${BLUE}unionfs
        ${YELLOW}SYS_SLIRP$GREEN=1                          Using system ${BLUE}slirp4netns
        ${YELLOW}SYS_TOOLS$GREEN=1                          Using all binaries from the system
                                             If they are not found in the system - auto return to the built-in

    ${RED}Other environment variables:
        ${GREEN}If inside RunImage:
            ${YELLOW}INSIDE_RUNIMAGE${GREEN}=1
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
        ${GREEN}Nvidia driver images directory:
            ${YELLOW}NVIDIA_DRIVERS_DIR${GREEN}=\"$NVIDIA_DRIVERS_DIR\"
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
        ${GREEN}squashfuse and unionfs PIDs:
            ${YELLOW}FUSE_PIDS${GREEN}=\"$FUSE_PIDS\"
        ${GREEN}The name of the user who runs runimage:
            ${YELLOW}RUNUSER${GREEN}=\"$RUNUSER\"
        ${GREEN}mksquashfs:
            ${YELLOW}MKSQFS${GREEN}=\"$MKSQFS\"
        ${GREEN}unsquashfs:
            ${YELLOW}UNSQFS${GREEN}=\"$UNSQFS\"
        ${GREEN}unionfs:
            ${YELLOW}UNIONFS${GREEN}=\"$UNIONFS\"
        ${GREEN}squashfuse:
            ${YELLOW}SQFUSE${GREEN}=\"$SQFUSE\"
        ${GREEN}bwrap:
            ${YELLOW}BUWRAP${GREEN}=\"$BUWRAP\"
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
        ${YELLOW}/usr/bin/runupdate$GREEN                For runimage update

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
        ${YELLOW}SANDBOX_HOME_DIR$GREEN and ${YELLOW}PORTABLE_HOME_DIR$GREEN point to a specific directory or create it in the absence of.

        RunImage uses fakechroot and fakeroot, which allows you to use root commands, including in
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
                in windowed/full screen mode (see ${YELLOW}XEPHYR_*$GREEN environment variables)
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
                ${YELLOW}{/path/new_runimage_name} {-zstd|-xz|-lz4} {zstd compression level 1-19}${GREEN}
            By default, runimage is created in the current directory with a standard name and
                with lz4 compression. If a new RunImage is successfully build, the old one is deleted.
                (see ${YELLOW}KEEP_OLD_BUILD${GREEN} ${YELLOW}BUILD_WITH_EXTENSION${GREEN} ${YELLOW}CMPRS_ALGO${GREEN} ${YELLOW}ZSDT_CMPRS_LVL${GREEN})

        ${RED}RunImage update:${GREEN}
            Allows you to update packages and rebuild RunImage. In unpacked form, automatic build will
                not be performed. When running an update, you can also pass arguments for a new build.
                (see RunImage build) (also see /usr/bin/runupdate)
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
                ${BLUE}--help      ${RED}|${BLUE}-h${GREEN}             Show this usage info
                ${BLUE}--shell     ${RED}|${BLUE}-s$GREEN  $YELLOW{args}$GREEN     Launch host shell (socat + ptyspawn)
                ${BLUE}--superuser ${RED}|${BLUE}-su${GREEN} $YELLOW{args}$GREEN     Execute command as superuser
                ${BLUE}--terminal  ${RED}|${BLUE}-t${GREEN}  $YELLOW{args}$GREEN     Execute command in host terminal

        ${RED}For Nvidia users with a proprietary driver:${GREEN}
            If the nvidia driver version does not match in runimage and in the host, runimage
                will make an image with the nvidia driver of the required version (requires internet)
                or will download a ready-made image from the github repository and further used as
                an additional module to runimage.
            You can download a ready-made driver image from the releases or build driver image manually:
                ${BLUE}https://github.com/VHSgunzo/runimage-nvidia-drivers${GREEN}
            In runimage, a fake version of the nvidia driver is installed by default to reduce the size:
                ${BLUE}https://github.com/VHSgunzo/runimage-fake-nvidia-driver${GREEN}
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
}

if [[ "$EUID" == 0 && "$ALLOW_ROOT" != 1 ]]
    then
        error_msg "root user is not allowed!"
        console_info_notify
        echo -e "${RED}\t\t\tDo not run RunImage as root!"
        echo -e "If you really need to run it as root set the ${YELLOW}ALLOW_ROOT${GREEN}=1 ${RED}environment variable.$RESETCOLOR"
        exit 1
fi

if [ $(cat /proc/sys/kernel/pid_max 2>/dev/null) -lt 4194304 ]
    then
        warn_msg "PID_MAX is less than 4194304!"
        if [ "$EUID" == 0 ]
            then
                info_msg "Increasing PID_MAX to 4194304..."
                echo kernel.pid_max=4194304 >> /etc/sysctl.d/98-pid_max.conf
                echo 4194304 > /proc/sys/kernel/pid_max
            else
                console_info_notify
                echo -e "${YELLOW}For better stability, recommended to increase PID_MAX to 4194304:"
                echo -e "${RED}# ${GREEN}sudo sh -c 'echo kernel.pid_max=4194304 >> /etc/sysctl.d/98-pid_max.conf'"
                echo -e "${RED}# ${GREEN}sudo sh -c 'echo 4194304 > /proc/sys/kernel/pid_max'$RESETCOLOR"
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

case "$RUNSRCNAME" in
    Run*|runimage*|$RUNROOTFSTYPE)
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
            --run-attach |--rA) set_default_option ;;
            --run-procmon|--rPm) set_default_option
                                    NO_RPIDSMON=1 ; QUIET_MODE=1 ;;
            --run-update |--rU) if [ -n "$RUNIMAGE" ]
                                    then
                                        OVERFS_MODE=1
                                        KEEP_OVERFS=0
                                        OVERFS_ID="upd$(date +"%H%M%S").$RUNPID"
                                    else
                                        OVERFS_MODE=0
                                        unset OVERFS_ID KEEP_OVERFS
                                fi
                                SQFUSE_REMOUNT=0 ; ALLOW_BG=0 ; ENABLE_HOSTEXEC=0 ;;
        esac
esac

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
elif [[ ! -n "$DISPLAY" && ! -n "$WAYLAND_DISPLAY" && -n "$XDG_SESSION_TYPE" ]]
    then
        export DISPLAY="$(who|grep "$RUNUSER"|grep -v "ttyS"|\
                          grep -om1 '(.*)$'|sed 's/(//;s/)//')"
fi

xhost +si:localuser:$RUNUSER &>/dev/null
[[ "$EUID" == 0 && "$RUNUSER" != "root" ]] && \
    xhost +si:localuser:root &>/dev/null

ulimit -n $(ulimit -n -H) &>/dev/null

if [ "$UNSHARE_DEF_MOUNTS" != 1 ]
    then
        DEF_MOUNTS_BIND=(
            '--bind-try' '/mnt' '/mnt'
            '--bind-try' '/media' '/media'
        )
        runbinds=("/run/media")
    else
        warn_msg "Default mount points are unshared!"
        unset runbinds
fi

[[ ! -n "$XDG_RUNTIME_DIR" || "$XDG_RUNTIME_DIR" != "/run/user/$EUID" ]] && \
    export XDG_RUNTIME_DIR="/run/user/$EUID"
XDG_RUN_BIND=(
    "--tmpfs" "/run"
    "--chmod" "0775" "/run"
    "--dir" "$XDG_RUNTIME_DIR"
    "--chmod" "0700" "$XDG_RUNTIME_DIR"
)
[ "$UNSHARE_UDEV" != 1 ] && \
    runbinds+=("/run/udev")||\
    warn_msg "UDEV is unshared!"
if [[ "$SHARE_SYSTEMD" == 1 && -d "/run/systemd" ]]
    then
        warn_msg "SystemD is shared!"
        runbinds+=("/run/systemd")
fi
XDG_DBUS=(
    "$XDG_RUNTIME_DIR/bus"
    "$XDG_RUNTIME_DIR/dbus-1"
)
if [ "$UNSHARE_PIDS" == 1 ]
    then
        warn_msg "Host PIDs are unshared!"
        UNSHARE_BIND+=("--unshare-pid")
        [ "$UNSHARE_DBUS" != 1 ] && \
            runbinds+=(
                "/run/dbus"
                "${XDG_DBUS[@]}"
            )
        runbinds+=(
            "$XDG_RUNTIME_DIR/pulse"
            "$XDG_RUNTIME_DIR/pipewire-0"
            "$XDG_RUNTIME_DIR/pipewire-0.lock"
        )
    else
        runbinds+=("/run/utmp")
        [ "$UNSHARE_DBUS" != 1 ] && \
            runbinds+=(
                "/run/dbus"
                "$XDG_RUNTIME_DIR"
            )
fi
if [ "$UNSHARE_DBUS" == 1 ]
    then
        warn_msg "DBUS is unshared!"
        UNSHARE_BIND+=("--unsetenv" "DBUS_SESSION_BUS_ADDRESS")
        if [ "$UNSHARE_PIDS" != 1 ]
            then
                for runbind in "$XDG_RUNTIME_DIR"/* "$XDG_RUNTIME_DIR"/.*
                    do
                        [[ ! "${XDG_DBUS[@]}" =~ "$runbind" ]] && \
                            runbinds+=("$runbind")
                done
        fi
fi
for bind in "${runbinds[@]}"
    do XDG_RUN_BIND+=("--bind-try" "$bind" "$bind")
done

if [[ "$NO_RPIDSMON" != 1 && "$ALLOW_BG" != 1 ]]
    then
        (wait_rpids=15
        while [[ ! -n "$oldrpids" && "$wait_rpids" -gt 0 ]]
            do
                oldrpids="$(get_child_pids "$RUNPID")"
                wait_rpids="$(( $wait_rpids - 1 ))"
                sleep 0.01 2>/dev/null
        done
        while ps -o pid= -p $oldrpids &>/dev/null
            do
                newrpids="$(get_child_pids "$RUNPID")"
                if [ ! -n "$newrpids" ]
                    then
                        if [ "$wait_rpids" -gt 0 ]
                            then
                                wait_rpids="$(( $wait_rpids - 1 ))"
                                sleep 0.01 2>/dev/null
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
                sleep 0.5 2>/dev/null
        done) &
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
           SYS_SQFUSE=1 SYS_BUWRAP=1 \
           SYS_UNIONFS=1 SYS_SLIRP=1

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

if [ "$SYS_UNIONFS" == 1 ] && is_sys_exe unionfs
    then
        info_msg "The system unionfs is used!"
        export UNIONFS="$(which_sys_exe unionfs)"
    else
        [ -x "$(which_sys_exe fusermount3)" ] && \
            export UNIONFS="$RUNSTATIC/unionfs3" || \
            export UNIONFS="$RUNSTATIC/unionfs"
fi

if [ "$EUID" != 0 ]
    then
        if [ ! -f '/proc/self/ns/user' ]
            then
                SYS_BUWRAP=1
                [ ! -n "$(echo "$PATH"|grep -wo '^/usr/bin:')" ] && \
                    export PATH="/usr/bin:$PATH"
                if [ ! -x "$(find "$(which_exe bwrap)" -perm -u=s 2>/dev/null)" ]
                    then
                        [ ! -x '/tmp/bwrap' ] && \
                            rm -rf '/tmp/bwrap' && \
                            cp "$RUNSTATIC/bwrap" '/tmp/'
                        error_msg 'The kernel does not support user namespaces!'
                        console_info_notify
                        echo -e "${YELLOW}You need to install SUID Bubblewrap into the system:"
                        echo -e "${RED}# ${GREEN}sudo cp -f /tmp/bwrap /usr/bin/ && sudo chmod u+s /usr/bin/bwrap"
                        echo -e "${RED}\n[NOT RECOMMENDED]: ${YELLOW}Or run as the root user."
                        echo -e "${YELLOW}\nOr install a kernel with user namespaces support."
                        echo -e "[RECOMMENDED]: XanMod kernel -> ${BLUE}https://xanmod.org$RESETCOLOR"
                        exit 1
                fi
        elif [ "$(cat '/proc/sys/kernel/unprivileged_userns_clone' 2>/dev/null)" == 0 ]
            then
                error_msg "unprivileged_userns_clone is disabled!"
                console_info_notify
                echo -e "${YELLOW}You need to enable unprivileged_userns_clone:"
                echo -e "${RED}# ${GREEN}sudo sh -c 'echo kernel.unprivileged_userns_clone=1 >> /etc/sysctl.d/98-userns.conf'"
                echo -e "${RED}# ${GREEN}sudo sh -c 'echo 1 > /proc/sys/kernel/unprivileged_userns_clone'$RESETCOLOR"
                exit 1
        elif [ "$(cat '/proc/sys/user/max_user_namespaces' 2>/dev/null)" == 0 ]
            then
                error_msg "max_user_namespaces is disabled!"
                console_info_notify
                echo -e "${YELLOW}You need to enable max_user_namespaces:"
                echo -e "${RED}# ${GREEN}sudo sh -c 'echo user.max_user_namespaces=10000 >> /etc/sysctl.d/98-userns.conf'"
                echo -e "${RED}# ${GREEN}sudo sh -c 'echo 10000 > /proc/sys/user/max_user_namespaces'$RESETCOLOR"
                exit 1
        elif [ "$(cat '/proc/sys/kernel/userns_restrict' 2>/dev/null)" == 1 ]
            then
                error_msg "userns_restrict is enabled!"
                console_info_notify
                echo -e "${YELLOW}You need to disabled userns_restrict:"
                echo -e "${RED}# ${GREEN}sudo sh -c 'echo kernel.userns_restrict=0 >> /etc/sysctl.d/98-userns.conf'"
                echo -e "${RED}# ${GREEN}sudo sh -c 'echo 0 > /proc/sys/kernel/userns_restrict'$RESETCOLOR"
                exit 1
        fi
fi

if [ "$SYS_BUWRAP" == 1 ] && is_sys_exe bwrap
    then
        info_msg "The system Bubblewrap is used!"
        export BUWRAP="$(which_sys_exe bwrap)"
    else
        export BUWRAP="$RUNSTATIC/bwrap"
fi
if [[ "$SYS_BUWRAP" == 1 && "$EUID" != 0 && \
      -x "$(find "$BUWRAP" -perm -u=s 2>/dev/null)" ]]
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
                cleanup force
                exit 1
        fi
        export RUNROOTFS="$RO_MNT/rootfs"
fi

if [ "$OVERFS_MODE" != 0 ] && [[ "$OVERFS_MODE" == 1 || "$KEEP_OVERFS" == 1 || -n "$OVERFS_ID" ]]
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
        mkdir -p "$OVERFS_DIR"/{layers,mnt}
        export OVERFS_MNT="$OVERFS_DIR/mnt"
        BRUNDIR="$OVERFS_MNT"
        "$UNIONFS" -f -o max_files=$(ulimit -n -H),hide_meta_files,cow,noatime \
                      -o $([ "$EUID" != 0 ] && echo relaxed_permissions),uid=$EUID,gid=$(id -g) \
                      -o dirs="$OVERFS_DIR/layers"=RW:"$([ -n "$RO_MNT" ] && echo "$RO_MNT"||\
                         echo "$RUNDIR")"=RO "$OVERFS_MNT" &>/dev/null &
        UNIONFS_PID="$!"
        export FUSE_PIDS="$UNIONFS_PID $FUSE_PIDS"
        if ! mount_exist "$UNIONFS_PID" "$OVERFS_MNT"
            then
                error_msg "Failed to mount RunImage in OverlayFS mode!"
                cleanup force
                exit 1
        fi
        export RUNROOTFS="$OVERFS_MNT/rootfs"
fi

if [ -n "$AUTORUN" ]
    then
        AUTORUN0ARG=($AUTORUN)
        info_msg "Autorun mode: ${AUTORUN[@]}"
        if NO_NVIDIA_CHECK=1 QUIET_MODE=1 ALLOW_BG=0 SANDBOX_NET=0 bwrun \
            /usr/bin/sh -c "[ -x '/usr/bin/$AUTORUN0ARG' ]"
            then
                RUNSRCNAME="$AUTORUN0ARG"
            else
                error_msg "$AUTORUN0ARG not found in /usr/bin"
                cleanup force
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
        [[ -n "$SANDBOX_HOME_DIR" && ! -d "$SANDBOX_HOME_DIR" ]] && \
            try_mkhome "$SANDBOX_HOME_DIR"
        if [ ! -d "$SANDBOX_HOME_DIR" ]
            then
                if [ -d "$SANDBOXHOMEDIR/$RUNSRCNAME" ]
                    then SANDBOX_HOME_DIR="$SANDBOXHOMEDIR/$RUNSRCNAME"
                elif [[ -n "$RUNIMAGE" && -d "$SANDBOXHOMEDIR/$RUNIMAGENAME" ]]
                    then SANDBOX_HOME_DIR="$SANDBOXHOMEDIR/$RUNIMAGENAME"
                elif [ -d "$SANDBOXHOMEDIR/Run" ]
                    then SANDBOX_HOME_DIR="$SANDBOXHOMEDIR/Run"
                fi
        fi
    else unset SANDBOX_HOME_DIR
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
        if [[ "$SANDBOX_HOME" == 1 || "$SANDBOX_HOME_DL" == 1 ]] && \
            [ ! -d "$SANDBOX_HOME_DIR" ]
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
            [[ -n "$PORTABLE_HOME_DIR" && ! -d "$PORTABLE_HOME_DIR" ]] && \
                try_mkdir "$PORTABLE_HOME_DIR"
            if [ -d "$PORTABLE_HOME_DIR" ]
                then
                    export HOME="$PORTABLE_HOME_DIR"
                    SET_HOME_DIR=1
                    export PORTABLE_HOME=1
            elif [[ "$PORTABLE_HOME" == 1 || -d "$PORTABLEHOMEDIR/$RUNSRCNAME" ]]
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
   -f "$SANDBOX_NET_RESOLVCONF" || -f "$SANDBOX_NET_HOSTS" ||\
   "$SANDBOX_NET_SHARE_HOST" == 1 ]] && \
   SANDBOX_NET=1

if [[ "$SANDBOX_NET" == 1 && ! -e '/dev/net/tun' ]]
    then
        tun_err_text="SANDBOX_NET enabled, but /dev/net/tun not found!"
        disable_sandbox_net() {
            unset SANDBOX_NET SANDBOX_NET_CIDR SANDBOX_NET_HOSTS SANDBOX_NET_MAC \
                    SANDBOX_NET_MTU SANDBOX_NET_RESOLVCONF SANDBOX_NET_TAPNAME
            warn_msg "SANDBOX_NET is disabled for now!"
        }
        if [ "$EUID" == 0 ]
            then
                warn_msg "$tun_err_text"
                if ! (modinfo tun|grep -wo builtin &>/dev/null) && \
                   ! (grep -owm1 tun /proc/modules &>/dev/null)
                    then
                        info_msg "Trying to load tun/tap module..."
                        if ! modprobe tun
                            then
                                error_msg "Failed to load tun/tap module!"
                                disable_sandbox_net
                        fi
                fi
            else
                error_msg "$tun_err_text"
                console_info_notify
                echo -e "${YELLOW}You need to load tun/tap module and add it to autostart:"
                echo -e "${RED}# ${GREEN}sudo modprobe tun"
                disable_sandbox_net
        fi
fi

if [[ "$SANDBOX_NET" == 1 || "$NO_NET" == 1 ]] && [ "$UNSHARE_DBUS" != 1 ] && \
    [[ "$DBUS_SESSION_BUS_ADDRESS" =~ "unix:abstract" ]]
    then
        DBUSP_SOCKET="/tmp/.rdbus.$RUNPID"
        info_msg "Launching socat dbus proxy..."
        socat UNIX-LISTEN:"$DBUSP_SOCKET",reuseaddr,fork \
            ABSTRACT-CONNECT:"$(echo "$DBUS_SESSION_BUS_ADDRESS"|\
                                sed 's|unix:abstract=||g;s|,guid=.*$||g')" &
        DBUSP_PID=$!
        sleep 0.05
        if [[ -n "$DBUSP_PID" && -d "/proc/$DBUSP_PID" && -S "$DBUSP_SOCKET" ]]
            then
                SETENV_ARGS+=("--setenv" "DBUS_SESSION_BUS_ADDRESS" "unix:path=$DBUSP_SOCKET")
            else
                error_msg "Failed to start socat dbus proxy!"
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

[[ -d "$BRUNDIR" && "$OVERFS_MNT" == "$BRUNDIR" ]]||\
    BRUNDIR="$RUNDIR"
if [ "$NO_RUNDIR_BIND" != 1 ]
    then RUNDIR_BIND=(
            "--bind-try" "$BRUNDIR" "/var/RunDir"
            "--setenv" "RUNDIR" "/var/RunDir"
            "--setenv" "RUNSTATIC" "/var/RunDir/static"
            "--setenv" "RUNROOTFS" "/var/RunDir/rootfs"
            "--setenv" "RUNRUNTIME" "/var/RunDir/static/runtime-fuse2-all"
        )
    else warn_msg "Binding RunDir is disabled!"
fi

add_bin_pth "$HOME/.local/bin:/bin:/sbin:/usr/bin:/usr/sbin:\
/usr/lib/jvm/default/bin:/usr/local/bin:/usr/local/sbin:\
/opt/cuda/bin:$HOME/.cargo/bin:$SYS_PATH:/var/RunDir/static"
[ -n "$LD_LIBRARY_PATH" ] && \
    add_lib_pth "$LD_LIBRARY_PATH"

if [ "$ENABLE_HOSTEXEC" == 1 ]
    then
        warn_msg "The HOSTEXEC option is enabled!"
        ([ -n "$SYS_HOME" ] && \
            export HOME="$SYS_HOME"
        JOBNUMFL="$EXECFLDIR/job"
        mkdir -p "$EXECFLDIR" 2>/dev/null
        mkfifo "$JOBNUMFL" 2>/dev/null
        unset jobnum
        while [[ -d "/proc/$RUNPID" && -d "$EXECFLDIR" ]]
            do
                jobnum=$(( $jobnum + 1 ))
                execjobdir="$EXECFLDIR/$jobnum"
                execjobfl="$execjobdir/exec"
                execjoboutfl="$execjobdir/out"
                execjobstatfl="$execjobdir/stat"
                mkdir "$execjobdir" 2>/dev/null
                mkfifo "$execjobfl" 2>/dev/null
                mkfifo "$execjoboutfl" 2>/dev/null
                mkfifo "$execjobstatfl" 2>/dev/null
                tee <<<"$jobnum" "$JOBNUMFL" &>/dev/null
                if [ -e "$execjobfl" ]
                    then
                        (cat "$execjobfl" 2>/dev/null|"$RUNSTATIC/bash" &>"$execjoboutfl" &
                        execjobpid=$!
                        tee <<<"$execjobpid" "$execjobstatfl" &>/dev/null
                        wait $execjobpid 2>/dev/null
                        execstat=$?
                        tee <<<"$execstat" "$execjobstatfl" &>/dev/null) &
                fi
        done) &
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

VAR_BIND+=(
    "--bind-try" "/var/mnt" "/var/mnt"
    "--bind-try" "/var/home" "/var/home"
    "--bind-try" "/var/roothome" "/var/roothome"
    "--bind-try" "/var/log/wtmp" "/var/log/wtmp"
    "--bind-try" "/var/log/lastlog" "/var/log/lastlog"
)
if [ ! -w "$RUNROOTFS" ]
    then
        VAR_BIND+=(
            "--tmpfs" "/var/log"
            "--tmpfs" "/var/tmp"
        )
fi

if [ "$UNSHARE_USERS" == 1 ]
    then
        warn_msg "Users are unshared!"
        USERS_BIND+=("--unshare-user-try")
        if ! grep -wo "^$RUNUSER:x:$EUID:0" "$RUNROOTFS/etc/passwd" &>/dev/null
            then
                if [ -w "$RUNROOTFS" ]
                    then
                        add_unshared_user "$RUNROOTFS/etc/passwd"
                    else
                        cp -f "$RUNROOTFS/etc/group" "$UNGROUPFL" 2>/dev/null
                        cp -f "$RUNROOTFS/etc/passwd" "$UNPASSWDFL" 2>/dev/null
                        add_unshared_user "$UNPASSWDFL"
                        USERS_BIND+=(
                            "--bind-try" "$UNGROUPFL" "/etc/group"
                            "--bind-try" "$UNPASSWDFL" "/etc/passwd"
                        )
                fi
        fi
    else
        USERS_BIND+=(
            "--ro-bind-try" "/etc/group" "/etc/group"
            "--ro-bind-try" "/etc/passwd" "/etc/passwd"
        )
fi

if [ "$UNSHARE_MODULES" != 1 ]
    then
        unset libmodules
        MODULES_BIND=("--ro-bind-try")
        if [ -d "/lib/modules" ]
            then libmodules="/lib/modules"
        elif [ -d "/usr/lib/modules" ]
            then libmodules="/usr/lib/modules"
        fi
        MODULES_BIND+=("$libmodules" "/usr/lib/modules")
    else
        warn_msg "Kernel modules are unshared!"
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
            then bwrun /usr/bin/$AUTORUN "$@"
            else bwrun /usr/bin/"${AUTORUN[@]}" "$@"
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
                    --run-desktop|--rD) bwrun "/usr/bin/rundesktop" ;;
                    --run-shell  |--rS) shift ; bwrun "${RUN_SHELL[@]}" "$@" ;;
                    --run-procmon|--rPm) shift ; bwrun "/usr/bin/rpidsmon" "$@" ;;
                    --run-build  |--rB) shift ; run_build "$@" ;;
                    *) bwrun "$@" ;;
                esac
        fi
fi
exit $?
##############################################################################
