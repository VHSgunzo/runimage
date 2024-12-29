#!/usr/bin/env bash
shopt -s extglob

DEVELOPERS="VHSgunzo"
export RUNIMAGE_VERSION='0.40.1'

RED='\033[1;91m'
BLUE='\033[1;94m'
GREEN='\033[1;92m'
YELLOW='\033[1;33m'
RESETCOLOR='\033[1;00m'

export RUNPPID="$PPID"
export RUNPID="$BASHPID"
export REUIDDIR="/tmp/.r$EUID"
export RUNTMPDIR="$REUIDDIR/run"
export RUNPIDDIR="$RUNTMPDIR/$RUNPID"
export BWINFFL="$RUNPIDDIR/bwinf"
export RIMENVFL="$RUNPIDDIR/rimenv"
export SSRV_CPIDS_DIR="$RUNPIDDIR/cpids"
export SSRV_PID_FILE="$RUNPIDDIR/ssrv.pid"
export SSRV_NOSEP_CPIDS=1
export SSRV_ENV='SSRV_PID'

unset SESSION_MANAGER POSIXLY_CORRECT LD_PRELOAD ENV \
    NO_CRYPTFS_MOUNT NVIDIA_DRIVER_BIND BIND_LDSO_CACHE FUSE_PIDS

if [ ! -n "$SYS_PATH" ]
    then
        if [ -n "$SHARUN_DIR" ]
            then export SYS_PATH="$(sed "s|$SHARUN_DIR/bin:||g"<<<"$PATH")"
            else export SYS_PATH="$PATH"
        fi
fi

which_exe() { command -v "$@" ; }

is_exe() { [[ -x "$1" && -f "$1" ]] ; }

export_rusp() {
    export RUNUTILS="$RUNDIR/utils"
    export RUNSTATIC="$RUNDIR/static"
    [ "$RIM_SYS_TOOLS" == 1 ] && \
        export PATH="$SYS_PATH:$RUNSTATIC:$RUNUTILS"||\
        export PATH="$RUNSTATIC:$RUNUTILS:$SYS_PATH"
}

export_rimg() {
    local rpth="$(realpath "$1" 2>/dev/null)"
    local wrpth="$(realpath "$(which_exe "$1")" 2>/dev/null)"
    if is_exe "$rpth"
        then export RUNIMAGE="$rpth"
    elif is_exe "$wrpth"
        then export RUNIMAGE="$wrpth"
    else [ -n "$2" ] && \
        export RUNIMAGE="$2"||\
        export RUNIMAGE="$1"
    fi
}

export_rsrc() {
    local rspth="$(realpath -s "$1" 2>/dev/null)"
    local wrspth="$(realpath -s "$(which_exe "$1")" 2>/dev/null)"
    if is_exe "$rspth"
        then export RUNSRC="$rspth"
    elif is_exe "$wrspth"
        then export RUNSRC="$wrspth"
    else [ -n "$2" ] && \
        export RUNSRC="$2"||\
        export RUNSRC="$1"
    fi
}

export_rootfs_info() {
    export RUNROOTFS_VERSION="$(cat "$RUNROOTFS/.version" \
                            "$RUNROOTFS/.type" \
                            "$RUNROOTFS/.build" 2>/dev/null|\
                            sed ':a;/$/N;s/\n/./;ta')"
    export RUNROOTFSTYPE="$(cat "$RUNROOTFS/.type" 2>/dev/null)"
}

[[ ! -n "$LANG" || "$LANG" =~ "UTF8" ]] && \
    export LANG=en_US.UTF-8

if [[ -n "$RUNOFFSET" && -n "$ARG0" ]]
    then
        export_rusp
        [ ! -n "$RUNIMAGE" ] && \
        export_rimg "$ARG0" # KDE Neon, CachyOS, Puppy Linux bug
        export_rsrc "$ARG0" "$RUNIMAGE"
        export RUNIMAGEDIR="$(dirname "$RUNIMAGE" 2>/dev/null)"
        RUNIMAGENAME="$(basename "$RUNIMAGE" 2>/dev/null)"
    else
        [ ! -d "$RUNDIR" ] && \
        export RUNDIR="$(dirname "$(realpath "$0" 2>/dev/null)" 2>/dev/null)"
        export_rusp
        export RUNIMAGEDIR="$(realpath "$RUNDIR/../" 2>/dev/null)"
        [ ! -n "$RUNSRC" ] && \
        export_rsrc "$0" "$RUNDIR/Run"
fi

export RUNTTY="$(LANG= tty|grep -v 'not a')"
[[ ! "$RUNTTY" =~ tty|pts ]] && \
    NOT_TERM=1||NOT_TERM=0

export RUNROOTFS="$RUNDIR/rootfs"
export RUNRUNTIME="$RUNSTATIC/uruntime"
export RUNCONFIGDIR="$RUNIMAGEDIR/config"
export SANDBOXHOMEDIR="$RUNIMAGEDIR/sandbox-home"
export PORTABLEHOMEDIR="$RUNIMAGEDIR/portable-home"
export RUNSRCNAME="$(basename "$RUNSRC" 2>/dev/null)"
export RUNSTATIC_VERSION="$(cat "$RUNSTATIC/.version" 2>/dev/null)"
export_rootfs_info
export RUNRUNTIME_VERSION="$("$RUNRUNTIME" --runtime-version)"

nocolor() { sed -r 's|\x1B\[([0-9]{1,3}(;[0-9]{1,2};?)?)?[mGK]||g' ; }

error_msg() {
    echo -e "${RED}[ ERROR ][$(date +"%Y.%m.%d %T")]: $@ $RESETCOLOR"
    if [ "$NOT_TERM" == 1 ]
        then notify-send -a 'RunImage Error' "$(echo -e "$@"|nocolor)" 2>/dev/null &
    fi
}

info_msg() {
    if [ "$RIM_QUIET_MODE" != 1 ]
        then echo -e "${GREEN}[ INFO ][$(date +"%Y.%m.%d %T")]: $@ $RESETCOLOR"
            if [[ "$NOT_TERM" == 1 && "$RIM_NOTIFY" == 1 ]]
                then notify-send -a 'RunImage Info' "$(echo -e "$@"|nocolor)" 2>/dev/null &
            fi
    fi
}

warn_msg() {
    if [[ "$RIM_QUIET_MODE" != 1 && "$RIM_NO_WARN" != 1 ]]
        then echo -e "${YELLOW}[ WARNING ][$(date +"%Y.%m.%d %T")]: $@ $RESETCOLOR"
            if [[ "$NOT_TERM" == 1 && "$RIM_NOTIFY" == 1 ]]
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
                    if is_pid "$1" && [ -n "$(ls -A "$2" 2>/dev/null)" ]
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
    [[ -x "$(PATH="$SYS_PATH" which "$1" 2>/dev/null)" ]] && \
        return 0||return 1
}

which_sys_exe() { PATH="$SYS_PATH" which "$1" 2>/dev/null ; }

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
                    WGET_ARGS=(--no-check-certificate -t 3 -T 5 -w 0.5 "$URL" -O "$FILEDIR/$FILENAME")
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
                            dl_progress_pulsate() {
                                local ret=1
                                [[ "$URL" =~ '&key=' ]] && \
                                    local URL="$(echo "$URL"|sed "s|\&key=.*||g")"
                                [[ "$URL" =~ '&' && ! "$URL" =~ '&amp;' ]] && \
                                    local URL="$(echo "$URL"|sed "s|\&|\&amp;|g")"
                                if is_exe_exist yad
                                    then
                                        local yad_args=(
                                            --progress --pulsate --text="Download:\t$FILENAME\n$URL"
                                            --width=650 --height=40 --undecorated --skip-taskbar
                                            --no-buttons --text-align center --auto-close --auto-kill
                                            --center --fixed --on-top --no-escape --selectable-labels
                                        )
                                        "$@" &
                                        local exec_pid="$!"
                                        if is_pid "$exec_pid"
                                            then
                                                (while is_pid "$exec_pid"
                                                    do echo -e "#\n" ; sleep 0.1 2>/dev/null
                                                done)|yad "${yad_args[@]}" &>/dev/null &
                                                local yad_pid="$!"
                                                wait "$exec_pid" &>/dev/null
                                                ret="$?"
                                                kill "$yad_pid" &>/dev/null
                                        fi
                                elif is_exe_exist zenity
                                    then
                                        "$@"|zenity --progress --pulsate --text="$URL" --width=650 --height=40 \
                                            --auto-close --no-cancel --title="Download: $FILENAME"
                                        ret="$?"
                                fi
                                return "$ret"
                            }
                            if [ "$NO_ARIA2C" != 1 ] && \
                                is_exe_exist aria2c
                                then
                                    aria2c --no-conf -R -x 13 -s 13 --allow-overwrite --summary-interval=1 -o \
                                        "$FILENAME" -d "$FILEDIR" "$URL"|grep --line-buffered 'ETA'|\
                                        sed -u 's|(.*)| &|g;s|(||g;s|)||g;s|\[||g;s|\]||g'|\
                                        awk '{print$3"\n#Downloading at "$3,$2,$5,$6;system("")}'|\
                                    dl_progress
                            elif is_exe_exist curl
                                then
                                    curl -R --progress-bar --insecure --fail -L "$URL" -o \
                                        "$FILEDIR/$FILENAME" |& tr '\r' '\n'|sed '0,/100/{/100/d;}'|\
                                        sed -ur 's|[# ]+||g;s|.*=.*||g;s|.*|#Downloading at &\n&|g'|\
                                    dl_progress
                            elif is_exe_exist wget2
                                then
                                    dl_progress_pulsate wget2 "${WGET_ARGS[@]}"
                            elif is_exe_exist wget
                                then
                                    wget "${WGET_ARGS[@]}"|& tr '\r' '\n'|\
                                        sed -u 's/.* \([0-9]\+%\)\ \+\([0-9,.]\+.\) \(.*\)/\1\n#Downloading at \1\ ETA: \3/; s/^20[0-9][0-9].*/#Done./'|\
                                    dl_progress
                            else
                                err_no_downloader
                            fi
                            dl_ret "${PIPESTATUS[0]}"||return 1
                        else
                            if [ "$NO_ARIA2C" != 1 ] && is_exe_exist aria2c
                                then
                                    aria2c --no-conf -R -x 13 -s 13 --allow-overwrite -d "$FILEDIR" -o "$FILENAME" "$URL"
                            elif is_exe_exist curl
                                then
                                    curl -R --progress-bar --insecure --fail -L "$URL" -o "$FILEDIR/$FILENAME"
                            elif is_exe_exist wget2
                                then
                                    wget2 -q --force-progress "${WGET_ARGS[@]}"
                            elif is_exe_exist wget
                                then
                                    wget -q --show-progress "${WGET_ARGS[@]}"
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
                "https://developer.nvidia.com/downloads/vulkan-beta-${nvidia_version//.}-linux"
                "https://developer.nvidia.com/vulkan-beta-${nvidia_version//.}-linux"
                "https://developer.nvidia.com/linux-${nvidia_version//.}"
            )
            if try_dl "${driver_url_list[0]}" "$NVIDIA_DRIVERS_DIR"||\
               try_dl "${driver_url_list[1]}" "$NVIDIA_DRIVERS_DIR"
                then return 0
            elif try_dl "${driver_url_list[2]}" "$NVIDIA_DRIVERS_DIR"||\
                 try_dl "${driver_url_list[3]}" "$NVIDIA_DRIVERS_DIR"||\
                 try_dl "${driver_url_list[4]}" "$NVIDIA_DRIVERS_DIR" "$nvidia_driver_run"||\
                 try_dl "${driver_url_list[5]}" "$NVIDIA_DRIVERS_DIR" "$nvidia_driver_run"||\
                 try_dl "${driver_url_list[6]}" "$NVIDIA_DRIVERS_DIR" "$nvidia_driver_run"
                then
                    binary_files="mkprecompiled nvidia-cuda-mps-control nvidia-cuda-mps-srv \
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
                NVDRVMNT="$RUNPIDDIR/mnt/nv${nvidia_version}drv"
            info_msg "Mounting the nvidia driver image: $(basename "$1")"
            try_mkdir "$NVDRVMNT"
            "$SQFUSE" -f "$1" "$NVDRVMNT" -o ro &>/dev/null &
            FUSE_PID="$!"
            FUSE_PIDS="$FUSE_PID $FUSE_PIDS"
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
                if (RIM_SANDBOX_NET=0 RIM_NO_NET=0 bwrun /usr/bin/ldconfig -C "$RUNPIDDIR/ld.so.cache" 2>/dev/null)
                    then
                        try_mkdir "$RUNCACHEDIR"
                        if mv -f "$RUNPIDDIR/ld.so.cache" \
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
                                        BIND_LDSO_CACHE=1
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
                        BIND_LDSO_CACHE=1
                fi
        fi
    }
    if [ -e '/sys/module/nvidia/version' ]||\
        grep -owm1 nvidia /proc/modules &>/dev/null
        then
            unset NVDRVMNT nvidia_driver_dir
            export NVIDIA_DRIVERS_DIR="${RIM_NVIDIA_DRIVERS_DIR:=$RUNIMAGEDIR/nvidia-drivers}"
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
                                    NVDRVMNT="$RUNPIDDIR/mnt/nv${nvidia_version}drv"
                                    [ "$nvidia_version_inside" != "000.00.00" ] && \
                                        warn_msg "Nvidia driver version mismatch detected, trying to fix it"
                                    if [ ! -f "$NVIDIA_DRIVERS_DIR/$nvidia_version/64/nvidia_drv.so" ] && \
                                        [ ! -f "$RUNIMAGEDIR/$nvidia_driver_image" ] && \
                                        [ ! -f "$NVIDIA_DRIVERS_DIR/$nvidia_driver_image" ] && \
                                        [ ! -f "$NVDRVMNT/64/nvidia_drv.so" ] && \
                                        [ ! -f "$RUNDIR/nvidia-drivers/$nvidia_version/64/nvidia_drv.so" ] && \
                                        [ ! -f "$RUNDIR/nvidia-drivers/$nvidia_driver_image" ]
                                        then
                                            if RIM_NOTIFY=0 RIM_QUIET_MODE=0 get_nvidia_driver_image
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
                                    if [ "$RIM_UNSHARE_RUN" != 1 ]
                                        then
                                            NVXSOCKET="$(ls /run/nvidia-xdriver-* 2>/dev/null|head -1)"
                                            if [ -S "$NVXSOCKET" ]
                                                then XDG_RUN_BIND+=("--bind-try" "$NVXSOCKET" "$NVXSOCKET")
                                            fi
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
            [ ! -n "$(grep -ow "$1" 2>/dev/null<<<"$LIB_PATH")" ] && \
                LIB_PATH="${1}:${LIB_PATH}"
        else LIB_PATH="${1}"
    fi
}

add_bin_pth() {
    if [ -n "$BIN_PATH" ]
        then
            [ ! -n "$(grep -ow "$1" 2>/dev/null<<<"$BIN_PATH")" ] && \
                BIN_PATH="${1}:${BIN_PATH}"
        else BIN_PATH="${1}"
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
                    elif kill -2 $FUSE_PIDS 2>/dev/null
                        then DORM=1
                    else
                        error_msg "Failed to unmount: '$1'"
                        return 1
                    fi
            elif [ -d "$1" ]
                then DORM=1
            fi
            if [[ "$DORM" == 1 && -w "$1" ]]
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

choose_runpid_and() {
    local run="$1"; shift
    local runpids_num="$(get_runpids|wc -l)"
    if [ "$runpids_num" == 0 ]
        then no_runimage_msg
    elif [ "$runpids_num" == 1 ]
        then
            "$run" "$(get_runpids)" "$@"
            return $?
    else
        while true
            do
                local runpids=($(get_runpids))
                if [ -n "$runpids" ]
                    then
                        info_msg "Specify the RunImage RUNPID!"
                        for i in $(seq 0 $((${#runpids[@]}-1)))
                            do echo "$((i+1)))" "${runpids[$i]}"
                        done; echo "0) Exit"
                        read -p 'Enter RUNPID number: ' runpid_choice
                        if [ "$runpid_choice" == 0 ]
                            then exit
                        elif [[ "$runpid_choice" =~ ^[0-9]+$  && "$runpid_choice" -gt 0 && \
                            "$runpid_choice" -le ${#runpids[@]} ]]
                            then
                                runpid="${runpids[$(($runpid_choice-1))]}"
                                "$run" "$runpid" "$@"
                                return $?
                            else
                                error_msg "Invalid number!"
                                sleep 1
                        fi
                    else
                        no_runimage_msg
                        return 1
                fi
        done
    fi
}

run_attach() {
    get_runpids() { awk -F'/' '{print $(NF-1)}'<<<"$(get_sock '*')" 2>/dev/null ; }
    get_sock() {
        if [ "$act" == "portfw" ]
            then find "$RUNTMPDIR"/$1 -name 'portfw' 2>/dev/null
            else find "$RUNTMPDIR"/$1 -name '*sock' 2>/dev/null
        fi
    }
    attach_act() {
        if [ "$act" == "portfw" ]
            then
                info_msg "Port forwarding RunImage RUNPID: $1"
                RUNPORTFW="$(get_sock "$1")"
                shift
                exec "$CHISEL" client "unix:$RUNPORTFW" "$@"
            else
                info_msg "Exec RunImage RUNPID: $1"
                export SSRV_SOCK="unix:$(get_sock "$1")"
                export SSRV_ENV="all-:$(tr ' ' ','<<<"${!RIM_@}")"
                export SSRV_ENV_PIDS="$(get_child_pids "$(cat "$RUNTMPDIR/$1/ssrv.pid" 2>/dev/null)"|head -1)"
                shift
                exec "$SSRV_ELF" "$@"
        fi
    }
    no_runimage_msg() {
        error_msg "RunImage container socket not found!"
        return 1
    }
    case "$1" in
        exec) shift ; local act=exec ;;
        portfw) shift ; local act=portfw ;;
    esac
    if [[ "$1" =~ ^[0-9]+$ ]]
        then
            if [ -e "$(get_sock "$1")" ]
                then attach_act "$@"
                else
                    error_msg "RunImage container not found by RUNPID: $1"
                    return 1
            fi
        else
            choose_runpid_and attach_act "$@"
    fi
}

force_kill() {
    local ret=1
    get_runpids() { ls "$RUNTMPDIR" 2>/dev/null|grep -v "$RUNPID" ; }
    no_runimage_msg() {
        error_msg "Running RunImage containers not found!"
        return 1
    }
    if [[ "$1" =~ ^(-h|--help)$ ]]
        then echo "[ Usage ]: $RUNSRCNAME rim-kill [RUNPID RUNPID...|all]"
    elif [[ "$1" =~ ^[0-9]+$ ]]
        then
            for runpid in "$@"
                do
                    local runtmpdir="$RUNTMPDIR/$runpid"
                    if [ -e "$runtmpdir" ]
                        then
                            (kill "$runpid" 2>/dev/null||\
                            kill $(cat "$RUNTMPDIR/$runpid/rpids" 2>/dev/null) 2>/dev/null) && ret=0
                            sleep 0.1
                            rm -rf "$runtmpdir" 2>/dev/null
                        else
                            error_msg "RunImage container not found by RUNPID: $runpid"
                            exit 1
                    fi
            done
    elif [ "$1" == 'all' ]
        then
            (kill $(get_runpids) 2>/dev/null||\
            kill $(cat "$RUNTMPDIR"/*/rpids 2>/dev/null) 2>/dev/null) && ret=0
            local MOUNTPOINTS="$(grep -E "$([ -n "$RUNIMAGENAME" ] && \
                echo "$RUNIMAGENAME"||echo "$RUNIMAGEDIR")|.*/mnt/cryptfs.*$RUNIMAGEDIR|$RUNTMPDIR/.*/mnt/nv.*drv|unionfs.*$RUNIMAGEDIR" \
                /proc/self/mounts|grep -v "$RUNDIR"|awk '{print$2}')"
            if [ -n "$MOUNTPOINTS" ]
                then
                    (IFS=$'\n' ; for unmt in $MOUNTPOINTS
                        do try_unmount "$unmt"
                    done) && ret=0
            fi
            sleep 0.1
            rm -rf "$RUNTMPDIR" 2>/dev/null
    else
        choose_runpid_and kill 2>/dev/null && ret=0
        local runtmpdir="$RUNTMPDIR/$runpid"
        sleep 0.1
        rm -rf "$runtmpdir" 2>/dev/null
    fi
    [ "$ret" != 1 ] && info_msg "RunImage successfully killed!"
    return "$ret"
}

try_kill() {
    ret=1
    if [ -n "$1" ]
        then
            for pid in $1
                do
                    trykillnum=0
                    while is_pid "$pid"
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
    if [[ "$RIM_NO_CLEANUP" != 1 || "$1" == "force" ]]
        then
            if [ "$1" == "force" ]
                then
                    FORCE_UMOUNT=1
                    RIM_QUIET_MODE=1
                else unset FORCE_UMOUNT
            fi
            if [ -n "$FUSE_PIDS" ]
                then
                    [[ "$KEEP_CRYPTFS" != 1 || "$FORCE_UMOUNT" == 1 ]] && \
                        try_unmount "$CRYPTFS_MNT"
                    [[ "$RIM_KEEP_OVERFS" != 1 || "$FORCE_UMOUNT" == 1 ]] && \
                        try_unmount "$OVERFS_MNT"
                    try_unmount "$NVDRVMNT"
                    try_kill "$FUSE_PIDS"
            fi
            if [ -n "$DBUSP_PID" ]
                then
                    try_kill $DBUSP_PID
                    [ -S "$DBUSP_SOCKET" ] && \
                        rm -f "$DBUSP_SOCKET" 2>/dev/null
            fi
            try_kill "$(cat "$RPIDSFL" 2>/dev/null)"
            if [[ -d "$OVERFS_DIR" && "$RIM_KEEP_OVERFS" != 1 ]]
                then
                    info_msg "Removing OverlayFS..."
                    chmod 777 -R "${OVERFS_DIR}/workdir" 2>/dev/null
                    rm -rf "$OVERFS_DIR" 2>/dev/null
                    rmdir "$RUNOVERFSDIR" 2>/dev/null
            fi
            [ -d "$RUNPIDDIR" ] && \
                rm -rf "$RUNPIDDIR" 2>/dev/null && \
                rmdir "$RUNTMPDIR" 2>/dev/null && \
                rmdir "$REUIDDIR" 2>/dev/null
            if [ "$RIM_FORCE_KILL_PPID" == 1 ]
                then
                    if [ -n "$RUNIMAGE" ]
                        then
                            try_unmount "$RUNDIR"
                            kill -9 $(ps -oppid $RUNPPID)
                        else
                            kill -9 $RUNPPID
                    fi
                    rmdir "$REUIDDIR" 2>/dev/null
            fi
        else
            warn_msg "Cleanup is disabled!"
    fi
}

child_pids_walk() {
    echo "$1"
    for i in ${child_pids[$1]}
        do child_pids_walk "$i"
    done
}
get_child_pids() {
    if [ -n "$1" ]
        then
            declare -A child_pids
            while read pid ppid
                do child_pids[$ppid]+=" $pid"
            done < <(ps -eo user=,pid=,ppid=,cmd= 2>/dev/null|grep "^$RUNUSER"|\
                     grep -v "bash $RUNDIR/Run.sh"|grep -wv "$RUNPPID"|\
                     grep -Pv '\d+ sleep \d+'|awk '{print$2,$3}'|sort -nu)
            for i in "$@"
                do ps -o pid= -p $(child_pids_walk "$i") 2>/dev/null|grep -v "$i"
            done|sed 's|^[[:space:]]*||g'
        else return 1
    fi
}

is_pid() { [[ -n "$1" && -d "/proc/$1" ]]; }

is_valis_ipv4() {
    [[ "$1" =~ ^(([1-9]?[0-9]|1[0-9][0-9]|2([0-4][0-9]|5[0-5]))\.){3}([1-9]?[0-9]|1[0-9][0-9]|2([0-4][0-9]|5[0-5]))$ ]] && \
        return 0||return 1
}

wait_exist() {
    if [ -n "$1" ]
        then
            local wait_time=300
            while is_pid "$RUNPID" && [ "$wait_time" -gt 0 ]
                do
                    if [ -e "$1" ]
                        then return 0
                        else
                            wait_time="$(( $wait_time - 1 ))"
                            sleep 0.01 2>/dev/null
                    fi
            done
    fi
    return 1
}

export_ssrv_pid() {
    if [ "$RIM_UNSHARE_PIDS" == 1 ]
        then
            export SSRV_PID="$(ps -opid=,cmd= -p $(get_child_pids \
                "$(grep 'child-pid' "$BWINFFL" 2>/dev/null|grep -Po '\d+')") \
                    2>/dev/null|grep 'ssrv -srv'|awk 'NR==1{print$1}')"
            echo "$SSRV_PID" > "$SSRV_PID_FILE"
        else export SSRV_PID="$(cat "$SSRV_PID_FILE" 2>/dev/null)"
    fi
}

is_snet() { [[ "$RIM_SANDBOX_NET" == 1 && "$RIM_NO_NET" != 1 ]]; }

is_nonet() { [ "$RIM_NO_NET" == 1 ]; }

enable_portfw() {
    if [[ -n "$RIM_SNET_PORTFW" && "$RIM_SNET_PORTFW" != 0 ]]
        then
            info_msg "Enable port forwarding..."
            "$SSRV_ELF" /var/RunDir/static/chisel server -usock "$RUNPORTFW" -socks5 -reverse &>/dev/null &
            CHISEL_PID="$!"
            if ! is_pid "$CHISEL_PID"
                then
                    error_msg "Failed to start port forwarding server!"
                    cleanup force
                    exit 1
            fi
            if [ "$RIM_SNET_PORTFW" != 1 ]
                then
                    "$CHISEL" client "unix:$RUNPORTFW" $RIM_SNET_PORTFW &>/dev/null &
                    if ! is_pid "$!"
                        then
                            error_msg "Failed to start port forwarding: $RIM_SNET_PORTFW"
                            cleanup force
                            exit 1
                    fi
            fi
    fi
}

create_sandbox_net() {
    if is_pid "$SSRV_PID"
        then
            info_msg "Creating a network sandbox..."
            mkfifo "$SREADYFL"
            "$SLIRP" --configure --ready-fd=8 \
                $([ "$RIM_SNET_SHARE_HOST" == 1 ] || echo "--disable-host-loopback")  \
                $([ -n "$RIM_SNET_CIDR" ] && echo "--cidr=$RIM_SNET_CIDR") \
                $([ -n "$RIM_SNET_MTU" ] && echo "--mtu=$RIM_SNET_MTU") \
                $([ -n "$RIM_SNET_MAC" ] && echo "--macaddress=$RIM_SNET_MAC") \
                "$SSRV_PID" \
                $([ -n "$RIM_SNET_TAPNAME" ] && echo "$RIM_SNET_TAPNAME"||echo 'eth0') \
                8>"$SREADYFL" &
            SLIRP_PID="$!"
            SLIRP_READY="$(cat "$SREADYFL" 2>/dev/null)"
            rm -f "$SREADYFL"
    fi
    if ! (is_pid "$SLIRP_PID" && [ "$SLIRP_READY" == 1 ])
        then
            echo
            error_msg "Failed to create a network sandbox!"
            try_kill $SSRV_PID
            cleanup force
            exit 1
    fi
    if [ -n "$CHANGE_TAPIP" ]
        then
            info_msg "Changing a sandbox network tap IP: $RIM_SNET_TAPIP"
            "$SSRV_ELF" sh -c "$CHANGE_TAPIP"
    fi
    if [[ "$RIM_SNET_DROP_CIDRS" == 1 && -n "$DROP_CIDRS" ]]
        then
            info_msg "Dropping local CIDRs..."
            "$SSRV_ELF" sh -c "$DROP_CIDRS"
    fi
    enable_portfw
}

bwrun() {
    if [ "$RIM_NO_NVIDIA_CHECK" == 1 ]
        then warn_msg "Nvidia driver check is disabled!"
    elif [[ "$RIM_NO_NVIDIA_CHECK" != 1 && ! -n "$NVIDIA_DRIVER_BIND" ]]
        then check_nvidia_driver</dev/null
    fi
    [ "$BIND_LDSO_CACHE" == 1 ] && \
        LD_CACHE_BIND=("--bind-try" \
            "$RUNCACHEDIR/ld.so.cache" "/etc/ld.so.cache")||\
        unset LD_CACHE_BIND
    [[ ! -n "$SSRV_SOCK" || "$SSRV_SOCK" != 'unix:/'* ]] && \
        export SSRV_SOCK="unix:$RUNPIDDIR/sock"
    export SSRV_SOCK_PATH="$(sed "s|^unix:||"<<<"$SSRV_SOCK")"
    if [ ! -e "$SSRV_SOCK_PATH" ]
        then
            BWRAP_EXEC=("$BWRAP")
            [ "$RIM_ROOT" == 1 ] && \
                BWRAP_EXEC+=(--uid 0 --gid 0)
            if [[ -d "$OVERFS_DIR" && -d "$BOVERLAY_SRC" && "$RIM_NO_BWRAP_OVERLAY" != 1 ]]
                then
                    BWRAP_EXEC+=(
                        --overlay-src "$BOVERLAY_SRC"
                        --overlay "${OVERFS_DIR}/bwrap/rootfs"
                        "${OVERFS_DIR}/workdir"
                    )
                else
                    BWRAP_EXEC+=(--bind "$RUNROOTFS")
            fi
            BWRAP_EXEC+=(/
                "${RIM_BWRAP_ARGS[@]}"
                --info-fd 8
                --proc /proc
                --bind-try /sys /sys
                --dev-bind-try /dev /dev
                "${SETENV_ARGS[@]}" "${HOST_TOOLS_BIND[@]}"
                "${BWRAP_CAP[@]}" "${HOSTNAME_BIND[@]}"
                "${LOCALTIME_BIND[@]}" "${NSS_BIND[@]}"
                "${MODULES_BIND[@]}" "${DEF_MOUNTS_BIND[@]}"
                "${USERS_BIND[@]}" "${RUNDIR_BIND[@]}"
                "${VAR_BIND[@]}" "${MACHINEID_BIND[@]}"
                "${NVIDIA_DRIVER_BIND[@]}" "${TMP_BIND[@]}"
                "${NETWORK_BIND[@]}" "${XDG_RUN_BIND[@]}"
                "${LD_CACHE_BIND[@]}" "${TMPDIR_BIND[@]}"
                "${UNSHARE_BIND[@]}" "${HOME_BIND[@]}"
                "${XORG_CONF_BIND[@]}" "${BWRAP_BIND[@]}"
                "${FONTS_BIND[@]}" "${BOOT_BIND[@]}"
                "${PKGCACHE_BIND[@]}" "${THEMES_BIND[@]}"
                --setenv INSIDE_RUNIMAGE '1'
                --setenv RUNPID "$RUNPID"
                --setenv PATH "$BIN_PATH"
                --setenv FAKEROOTDONTTRYCHOWN 'true'
                --setenv XDG_CONFIG_DIRS "/etc/xdg:$XDG_CONFIG_DIRS"
                --setenv XDG_DATA_DIRS "/usr/local/share:/usr/share:$XDG_DATA_DIRS"
            )
            [ -n "$LIB_PATH" ] && \
                BWRAP_EXEC+=(--setenv LD_LIBRARY_PATH "$LIB_PATH")
            BWRAP_EXEC+=(/var/RunDir/static/tini -s -p SIGTERM -g --)
            if is_snet
                then
                    unset CHANGE_TAPIP DROP_CIDRS
                    export SREADYFL="$RUNPIDDIR/sready"
                    [ ! -n "$RIM_SNET_TAPNAME" ] && \
                        export RIM_SNET_TAPNAME="eth0"
                    if [ -n "$RIM_SNET_TAPIP" ]
                        then
                            if is_valis_ipv4 "$RIM_SNET_TAPIP"
                                then
                                    prefix=24
                                    if [ -n "$RIM_SNET_CIDR" ]
                                        then prefix="$(cut -d'/' -f2-<<<"$RIM_SNET_CIDR")"
                                        else export RIM_SNET_CIDR="$(rev<<<"$RIM_SNET_TAPIP"|cut -d'.' -f2-|rev).0/${prefix}"
                                    fi
                                    CHANGE_TAPIP="ip route del default via ${RIM_SNET_CIDR/0\/${prefix}/2} dev $RIM_SNET_TAPNAME ;\
                                        ip addr del ${RIM_SNET_CIDR/0\/${prefix}/100}/${prefix} broadcast ${RIM_SNET_CIDR/0\/${prefix}/255} dev $RIM_SNET_TAPNAME ;\
                                        ip addr add $RIM_SNET_TAPIP/${prefix} broadcast ${RIM_SNET_CIDR/0\/${prefix}/255} dev $RIM_SNET_TAPNAME ;\
                                        ip route add default via ${RIM_SNET_CIDR/0\/${prefix}/2} dev $RIM_SNET_TAPNAME"
                                else
                                    warn_msg "The IP address of the TAP interface is not valid!"
                            fi
                    fi
                    if [ "$RIM_SNET_DROP_CIDRS" == 1 ]
                        then
                            DROP_CIDRS=
                            for cidr in $(ip -o -4 a|grep -wv lo|awk '{print$4}')
                                do DROP_CIDRS+="iptables -A OUTPUT -d $cidr -j DROP ; "
                            done
                    fi
            fi
            if [[ "$RUNTTY" =~ 'tty' ]] || [[ "$RUNTTY" =~ 'pts' && "$RIM_IN_SAME_PTY" == 1 ]]
                then
                    wait_ssrv_pid() {
                        wait_exist "$BWINFFL"
                        unset SSRV_PID
                        while is_pid "$RUNPID" && ! is_pid "$SSRV_PID"
                            do
                                export_ssrv_pid
                                sleep 0.01 2>/dev/null
                        done
                    }
                    configure_net() {
                        wait_ssrv_pid
                        "$@"
                        while is_pid "$RUNPID" && is_pid "$SSRV_PID"
                            do sleep 0.5
                        done; try_kill "$SLIRP_PID $CHISEL_PID"
                    }
                    bwin() {
                        unfbwin() { unset -f bwin wait_exist is_pid is_snet ; unset "${!RIM_@}" ; }
                        [[ "$A_EXEC_ARGS" =~ ^declare ]] && \
                        eval "$A_EXEC_ARGS" && unset A_EXEC_ARGS
                        [[ "$A_BWRUNARGS" =~ ^declare ]] && \
                        eval "$A_BWRUNARGS" && unset A_BWRUNARGS
                        (unfbwin ; exec setsid /var/RunDir/static/ssrv -srv -env all &>/dev/null) &
                        wait_exist "$SSRV_PID_FILE"
                        is_snet && sleep 0.1
                        if [[ "$RUNTTY" =~ 'tty' && "$RIM_TTY_ALLOC_PTY" == 1 ]]
                            then unfbwin ; /var/RunDir/static/ssrv "${EXEC_ARGS[@]}" "${BWRUNARGS[@]}"
                            else unfbwin ; unset "${!SSRV_@}" ; "${EXEC_ARGS[@]}" "${BWRUNARGS[@]}"
                        fi
                        EXEC_STATUS="$?"
                        [ -e "$SSRV_SOCK_PATH" ] && \
                            rm -f "$SSRV_SOCK_PATH" 2>/dev/null
                        return $EXEC_STATUS
                    }
                    BWRUNARGS=("$@")
                    [ -n "$RIM_NO_NET" ] && export RIM_NO_NET
                    [ -n "$RIM_SANDBOX_NET" ] && export RIM_SANDBOX_NET
                    export A_EXEC_ARGS="$(EXEC_ARGS=("${RIM_EXEC_ARGS[@]}"); declare -p EXEC_ARGS 2>/dev/null)"
                    export A_BWRUNARGS="$(declare -p BWRUNARGS 2>/dev/null)"
                    export -f bwin wait_exist is_pid is_snet
                    wait_ssrv_pid &
                    if is_snet
                        then (configure_net create_sandbox_net) &
                    elif is_nonet
                        then (configure_net enable_portfw) &
                    fi
                    "${BWRAP_EXEC[@]}" sh -c bwin 8>"$BWINFFL"
                    [ -f "$BWINFFL" ] && rm -f "$BWINFFL" 2>/dev/null
                    return $?
                else
                    SSRV_UENV="$(tr ' ' ','<<<"${!RIM_@}")" \
                    "${BWRAP_EXEC[@]}" /var/RunDir/static/ssrv -srv -env all 8>"$BWINFFL" &>/dev/null &
                    wait_exist "$SSRV_PID_FILE"
                    export_ssrv_pid
                    if is_snet
                        then create_sandbox_net
                    elif is_nonet
                        then enable_portfw
                    fi
            fi
    fi
    "$SSRV_ELF" "${RIM_EXEC_ARGS[@]}" "$@"
    EXEC_STATUS="$?"
    [ -f "$BWINFFL" ] && \
        rm -f "$BWINFFL" 2>/dev/null
    kill $SSRV_PID 2>/dev/null
    [ -e "$SSRV_SOCK_PATH" ] && \
        rm -f "$SSRV_SOCK_PATH" 2>/dev/null
    return $EXEC_STATUS
}

overlayfs_list() {
    OLD_IFS="$IFS"
    IFS=$'\n'
    OVERFSLIST=($(ls -A "$RUNOVERFSDIR" 2>/dev/null))
    IFS="$OLD_IFS"
    if [ -n "$OVERFSLIST" ]
        then
            echo -e "${GREEN}OverlayFS:\t${BLUE}SIZE\tPATH\tID"
            for overfs_id in "${OVERFSLIST[@]}"
                do
                    LSTOVERFS_DIR="$RUNOVERFSDIR/$overfs_id"
                    echo -e "${BLUE}$(du -sh \
                        --exclude="$LSTOVERFS_DIR/mnt" \
                        --exclude="$LSTOVERFS_DIR/rootfs" \
                        --exclude="$LSTOVERFS_DIR/workdir" \
                        "$LSTOVERFS_DIR")\t\t${overfs_id}${RESETCOLOR}"
            done
        else
            error_msg "OverlayFS not found!"
            return 1
    fi
}

overlayfs_rm() {
    local ret=1
    OLD_IFS="$IFS"
    IFS=$'\n'
    OVERFSLIST=($(ls -A "$RUNOVERFSDIR" 2>/dev/null))
    IFS="$OLD_IFS"
    if [[ "$1" =~ ^(-h|--help)$ ]]
        then echo "[ Usage ]: rim-ofsrm [ID ID...|all]"
    elif [[ -n "$OVERFSLIST" || "$1" == 'all' ]]
        then
            if [[ -n "$1" || -n "$RIM_OVERFS_ID" ]]
                then
                    overfsrm() {
                        info_msg "Removing OverlayFS: $overfs_id"
                        if [ "$1" == 'force' ]
                            then
                                try_kill "$(lsof -n "$RMOVERFS_MNT" 2>/dev/null|sed 1d|awk '{print$2}'|sort -u)"
                                try_unmount "$RMOVERFS_MNT"
                        fi
                        chmod 777 -R "${RMOVERFS_DIR}/workdir" 2>/dev/null
                        rm -rf "$RMOVERFS_DIR" 2>/dev/null
                        rmdir "$RUNOVERFSDIR" 2>/dev/null
                        [ ! -d "$RMOVERFS_DIR" ] && \
                            info_msg "Removing completed!"
                    }
                    [ "$1" == 'all' ] && \
                    OVERFSRMLIST=("${OVERFSLIST[@]}")||\
                    OVERFSRMLIST=("$@" "$RIM_OVERFS_ID")
                    for overfs_id in "${OVERFSRMLIST[@]}"
                        do
                            RMOVERFS_DIR="$RUNOVERFSDIR/$overfs_id"
                            if [ -d "$RMOVERFS_DIR" ]
                                then
                                    RMOVERFS_MNT="$RMOVERFS_DIR/mnt"
                                    if [ -n "$(ls -A "$RMOVERFS_MNT" 2>/dev/null)" ]
                                        then
                                            info_msg "Maybe OverlayFS is currently in use: $overfs_id"
                                            while true
                                                do
                                                    read -p "$(echo -e "\t${RED}Are you sure you want to delete it? ${GREEN}(y/n) ${BLUE}> $RESETCOLOR")" yn
                                                    case $yn in
                                                        [Yy] ) overfsrm force && ret=0
                                                               break ;;
                                                        [Nn] ) break ;;
                                                    esac
                                            done
                                        else
                                            overfsrm && ret=0
                                    fi
                                    unset RMOVERFS_MNT
                                else
                                    error_msg "Not found OverlayFS: $overfs_id"
                            fi
                            unset RMOVERFS_DIR
                    done
                else
                    error_msg "Specify the OverlayFS ID!"
            fi
        else
            error_msg "OverlayFS not found!"
    fi
    return "$ret"
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

pkg_list() (
    RIM_QUIET_MODE=1
    RIM_SANDBOX_NET=0
    RIM_NO_NVIDIA_CHECK=1
    if bwrun which pacman &>/dev/null
        then bwrun pacman -Q 2>/dev/null
    elif bwrun which apt &>/dev/null
        then bwrun apt list --installed 2>/dev/null
    elif bwrun which apk &>/dev/null
        then bwrun apk list --installed 2>/dev/null
    elif bwrun which xbps-query &>/dev/null
        then bwrun xbps-query --list-pkgs 2>/dev/null
    else
        error_msg "The package manager cannot be detected!"
        exit 1
    fi
)

bin_list() {
    RIM_NO_NVIDIA_CHECK=1 RIM_QUIET_MODE=1 bwrun find /usr/bin/ /bin/ \
    -executable -type f -maxdepth 1 2>/dev/null|sed 's|/usr/bin/||g;s|/bin/||g'|sort -u
}

print_version() {
    info_msg "RunImage version: ${RED}$RUNIMAGE_VERSION"
    info_msg "RootFS version: ${RED}$RUNROOTFS_VERSION"
    info_msg "Static version: ${RED}$RUNSTATIC_VERSION"
    [ -n "$RUNRUNTIME_VERSION" ] && \
        info_msg "RunImage runtime version: ${RED}$RUNRUNTIME_VERSION"
}

run_update() {
    info_msg "RunImage update"
    RIM_ROOT=1 RIM_NO_NVIDIA_CHECK=1 RIM_QUIET_MODE=1 \
        bwrun rim-update "$@"
    UPDATE_STATUS="$?"
    case "$1" in
        -h|--help) echo -e \
    "\n    When running outside the container, rim-update can also take rim-build arguments
    to build a new RunImage in case of successful package updates." ; exit 1 ;;
        --shrink|--cleanup) shift ;;
    esac
    if [ "$UPDATE_STATUS" == 0 ]
        then
            if [ -e "$RUNPIDDIR/is_pkgs" ]
                then
                    rm -f "$RUNPIDDIR/is_pkgs"
                    try_rebuild_runimage "$@" && \
                        UPDATE_STATUS="$?"
                    [ "$UPDATE_STATUS" == 0 ] && \
                        info_msg "The update is complete!"
                else
                    info_msg "No package updates found!"
            fi
    fi
    [ "$UPDATE_STATUS" != 0 ] && \
        error_msg "The update failed!"
    return $UPDATE_STATUS
}

add_unshared_user() {
    if grep -qo ".*:x:$EUID:" "$1" &>/dev/null
        then sed -i "s|.*:x:$EUID:.*|$RUNUSER:x:$EUID:0:[^_^]:$HOME:/bin/sh|g" "$1"
        else echo "$RUNUSER:x:$EUID:0:[^_^]:$HOME:/bin/sh" >> "$1"
    fi
}

add_unshared_group() {
    if grep -o ".*:x:$EGID:" "$1" &>/dev/null
        then sed -i "s|.*:x:$EGID:.*|$RUNGROUP:x:$EGID:|g" "$1"
        else echo "$RUNGROUP:x:$EGID:" >> "$1"
    fi
}

try_rebuild_runimage() {
    if [ -n "$1" ]||[[ -n "$RUNIMAGE" && "$RIM_REBUILD_RUNIMAGE" == 1 ]]
        then (cd "$RUNIMAGEDIR" && run_build "$@")
    fi
}

is_cryptfs() {
    [[ -d "$CRYPTFS_DIR" && -f "$CRYPTFS_DIR/gocryptfs.conf" ]]||\
    [[ -d "$OVERFS_DIR" && -f "$OVERFS_DIR/layers/cryptfs/gocryptfs.conf" ]]
}

passwd_cryptfs() {
    if is_cryptfs
        then
            info_msg "Changing GoCryptFS rootfs password..."
            if gocryptfs --passwd "$CRYPTFS_DIR"
                then
                    try_rebuild_runimage "$@"
                    exit
                else
                    error_msg "Failed to change GoCryptFS rootfs password!"
                    exit 1
            fi
        else
            error_msg "RunImage rootfs is not encrypted!"
            exit 1
    fi
}

encrypt_rootfs() {
    if ! is_cryptfs
        then
            info_msg "Creating GoCryptFS rootfs directory..."
            try_mkdir "$CRYPTFS_DIR"
            if "$GOCRYPTFS" --init "$CRYPTFS_DIR"
                then
                    info_msg "Mounting GoCryptFS rootfs directory..."
                    try_mkdir "$CRYPTFS_MNT"
                    if "${CRYPTFS_ARGS[@]}"
                        then
                            info_msg "Updating sharun directory..."
                            upd_sharun() {
                                unset -f upd_sharun
                                rm -rf "$RUNDIR/sharun/shared"
                                "$RUNDIR/sharun/sharun" lib4bin -p -g -d "$RUNDIR/sharun" \
                                    $(cat "$RUNDIR/sharun/bin.list")
                            }
                            export -f upd_sharun
                            if bwrun sh -c upd_sharun
                                then
                                    info_msg "Encrypting RunImage rootfs..."
                                    if chmod u+rw -R "$RUNROOTFS" && mv -f "$RUNROOTFS"/{.,}* "$CRYPTFS_MNT"/
                                        then
                                            rm -rf "$RUNROOTFS"
                                            export RUNROOTFS="$CRYPTFS_MNT"
                                            export RIM_ZSDT_CMPRS_LVL=1
                                            try_rebuild_runimage "$@"
                                            try_unmount "$CRYPTFS_MNT"
                                            info_msg "Encryption is complete!"
                                            exit
                                        else
                                            error_msg "Failed to encrypt RunImage rootfs!"
                                            exit 1
                                    fi
                                else
                                    error_msg "Failed to update sharun directory!"
                                    exit 1
                            fi
                        else
                            error_msg "Failed to mount GoCryptFS rootfs directory!"
                            exit 1
                    fi
                else
                    error_msg "Failed to create GoCryptFS rootfs directory!"
                    exit 1
            fi
        else
            error_msg "RunImage rootfs is already encrypted!"
            exit 1
    fi
}

decrypt_rootfs() {
    if is_cryptfs
        then
            info_msg "Decrypting RunImage rootfs..."
            export RUNROOTFS="$BRUNDIR/rootfs"
            try_mkdir "$RUNROOTFS"
            if mv -f "$CRYPTFS_MNT"/{.,}* "$RUNROOTFS"/
                then
                    rm -rf "$BRUNDIR/sharun/shared"/*
                    if (for dir in bin lib
                        do ln -sfr "$RUNROOTFS/$dir" "$BRUNDIR/sharun/shared"/
                    done)
                        then
                            rm -rf "$CRYPTFS_DIR"
                            unset RIM_ZSDT_CMPRS_LVL
                            touch "$RUNROOTFS/.decfs"
                            try_rebuild_runimage "$@"
                            try_unmount "$CRYPTFS_MNT"
                            info_msg "Decryption is complete!"
                            exit
                        else
                            error_msg "Failed to update sharun directory!"
                            exit 1
                    fi
                else
                    error_msg "Failed to decrypt RunImage rootfs!"
                    exit 1
            fi
        else
            error_msg "RunImage rootfs is already decrypted!"
            exit 1
    fi
}

run_build() { "$RUNSTATIC/bash" "$RUNUTILS/rim-build" "$@" ; }

check_unshare_tmp() {
    if [ "$RIM_UNSHARE_TMP" == 1 ]
        then
            warn_msg "Host /tmp is unshared!"
            TMP_BIND+=("--tmpfs" "/tmp" "--bind-try" "$REUIDDIR" "$REUIDDIR")
        else TMP_BIND+=("--bind-try" "/tmp" "/tmp")
    fi
}

disable_sandbox_net() {
    warn_msg "RIM_SANDBOX_NET is disabled for now!"
    unset RIM_SNET_CIDR RIM_SNET_MAC \
        RIM_SNET_MTU RIM_SNET_TAPNAME \
        RIM_SNET_TAPIP RIM_SNET_SHARE_HOST \
        RIM_SNET_DROP_CIDRS RIM_SNET_PORTFW
    RIM_SANDBOX_NET=0
}

set_default_option() {
    RIM_NO_WARN=1
    RIM_TMP_HOME=0
    RIM_XORG_CONF=0
    RIM_SHARE_BOOT=0
    RIM_RUN_IN_ONE=0
    RIM_HOST_TOOLS=0
    RIM_SANDBOX_NET=0
    RIM_TMP_HOME_DL=0
    RIM_UNSHARE_NSS=1
    RIM_SHARE_FONTS=0
    RIM_UNSHARE_HOME=1
    RIM_SHARE_THEMES=0
    RIM_SANDBOX_HOME=0
    RIM_PORTABLE_HOME=0
    RIM_UNSHARE_USERS=1
    RIM_UNSHARE_HOSTS=1
    RIM_SANDBOX_HOME_DL=0
    RIM_NO_NVIDIA_CHECK=1
    RIM_UNSHARE_MODULES=1
    RIM_ENABLE_HOSTEXEC=0
    RIM_UNSHARE_HOSTNAME=1
    RIM_UNSHARE_LOCALTIME=1
    RIM_UNSHARE_RESOLVCONF=1
}

set_overfs_option() {
    set_default_option
    RIM_DESKTOP_INTEGRATION=0
    if [[ -n "$RUNIMAGE" && ! -n "$RIM_OVERFS_ID" ]]
        then
            RIM_OVERFS_MODE=1
            RIM_KEEP_OVERFS=0
            RIM_REBUILD_RUNIMAGE=1
            RIM_OVERFS_ID="${1}$(date +"%H%M%S").$RUNPID"
    fi
}

print_help() {
    RUNHOSTNAME="$(uname -a|awk '{print$2}')"
    echo -e "
${GREEN}RunImage ${RED}v${RUNIMAGE_VERSION} ${GREEN}by $DEVELOPERS
    ${RED}Usage:
        $RED┌──[$GREEN$RUNUSER$YELLOW@$BLUE${RUNHOSTNAME}$RED]─[$GREEN$PWD$RED]
        $RED└──╼ \$$GREEN $([ -n "$ARG0" ] && echo "$ARG0"||echo "$0") $GREEN{executable} $YELLOW{executable args}

        ${BLUE}rim-help   $GREEN                    Show this usage info
        ${BLUE}rim-version$GREEN                    Show runimage, rootfs, static, runtime version
        ${BLUE}rim-pkgls  $GREEN                    Show packages installed in runimage
        ${BLUE}rim-binlist$GREEN                  Show /usr/bin in runimage
        ${BLUE}rim-shell  $YELLOW  {args}$GREEN            Run runimage shell or execute a command in runimage shell
        ${BLUE}rim-desktop$GREEN                    Launch runimage desktop
        ${BLUE}rim-ofsls$GREEN                    Show the list of runimage OverlayFS
        ${BLUE}rim-ofsrm  $YELLOW  {id id ...|all}$GREEN   Remove OverlayFS
        ${BLUE}rim-build  $YELLOW  {build args}$GREEN      Build new runimage container
        ${BLUE}rim-update $YELLOW  {build args}$GREEN      Update packages and rebuild runimage
        ${BLUE}rim-kill   $GREEN                    Kill all running runimage containers
        ${BLUE}rim-psmon$YELLOW {RUNPIDs}$GREEN         Monitoring of processes running in runimage containers
        ${BLUE}rim-exec $YELLOW  {RUNPID} {args}$GREEN   Attach to a running runimage container or exec command

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
        ${YELLOW}RIM_NO_NET$GREEN=1                             Disables network access
        ${YELLOW}RIM_TMP_HOME$GREEN=1                           Creates tmpfs /home/${YELLOW}\$USER${GREEN} and /root in RAM and uses it as ${YELLOW}\$HOME
        ${YELLOW}RIM_TMP_HOME_DL$GREEN=1                        As above, but with binding ${YELLOW}\$HOME${GREEN}/Downloads directory
        ${YELLOW}RIM_SANDBOX_HOME$GREEN=1                       Creates sandbox home directory and bind it to /home/${YELLOW}\$USER${GREEN} or to /root
        ${YELLOW}RIM_SANDBOX_HOME_DL$GREEN=1                    As above, but with binding ${YELLOW}\$HOME${GREEN}/Downloads directory
        ${YELLOW}RIM_SANDBOX_HOME_DIR$GREEN=\"/path/dir\"         Specifies sandbox home directory and bind it to /home/${YELLOW}\$USER${GREEN} or to /root
        ${YELLOW}RIM_PORTABLE_HOME$GREEN=1                      Creates a portable home directory and uses it as ${YELLOW}\$HOME
        ${YELLOW}RIM_PORTABLE_HOME_DIR$GREEN=\"/path/dir\"        Specifies a portable home directory and uses it as ${YELLOW}\$HOME
        ${YELLOW}RIM_PORTABLE_CONFIG$GREEN=1                    Creates a portable config directory and uses it as ${YELLOW}\$XDG_CONFIG_HOME
        ${YELLOW}RIM_NO_CLEANUP$GREEN=1                         Disables unmounting and cleanup mountpoints
        ${YELLOW}RIM_UNSHARE_PIDS$GREEN=1                       Unshares all host processes
        ${YELLOW}RIM_UNSHARE_USERS$GREEN=1                      Don't bind-mount /etc/{passwd,group}
        ${YELLOW}RIM_SHARE_SYSTEMD$GREEN=1                      Shares SystemD from the host
        ${YELLOW}RIM_UNSHARE_DBUS$GREEN=1                       Unshares DBUS from the host
        ${YELLOW}RIM_UNSHARE_UDEV$GREEN=1                       Unshares UDEV from the host (/run/udev)
        ${YELLOW}RIM_UNSHARE_MODULES$GREEN=1                    Unshares kernel modules from the host (/usr/lib/modules)
        ${YELLOW}RIM_UNSHARE_LOCALTIME$GREEN=1                  Unshares localtime from the host (/etc/localtime)
        ${YELLOW}RIM_UNSHARE_NSS$GREEN=1                        Unshares NSS from the host (/etc/nsswitch.conf)
        ${YELLOW}RIM_UNSHARE_DEF_MOUNTS$GREEN=1                 Unshares default mount points (/mnt /media /run/media)
        ${YELLOW}RIM_NO_NVIDIA_CHECK$GREEN=1                    Disables checking the nvidia driver version
        ${YELLOW}RIM_NVIDIA_DRIVERS_DIR$GREEN=\"/path/dir\"     Specifies custom Nvidia driver images directory
        ${YELLOW}RIM_CACHEDIR$GREEN=\"/path/dir\"               Specifies custom runimage cache directory
        ${YELLOW}RIM_OVERFSDIR$GREEN=\"/path/dir\"              Specifies custom runimage OverlayFS directory
        ${YELLOW}RIM_OVERFS_MODE$GREEN=1                        Enables OverlayFS mode
        ${YELLOW}RIM_KEEP_OVERFS$GREEN=1                        Enables OverlayFS mode with saving after closing runimage
        ${YELLOW}RIM_OVERFS_ID$GREEN=ID                         Specifies the OverlayFS ID
        ${YELLOW}RIM_KEEP_OLD_BUILD$GREEN=1                     Creates a backup of the old RunImage when building a new one
        ${YELLOW}RIM_CMPRS_ALGO$GREEN={zstd|xz|lz4}             Specifies the compression algo for runimage build
        ${YELLOW}RIM_ZSDT_CMPRS_LVL$GREEN={1-22}                Specifies the compression ratio of the zstd algo for runimage build
        ${YELLOW}RIM_SHELL$GREEN=\"shell\"                      Selects ${YELLOW}\$SHELL$GREEN in runimage
        ${YELLOW}RIM_NO_CAP$GREEN=1                             Disables Bubblewrap capabilities (Default: ALL, drop CAP_SYS_NICE)
                                                you can also use /usr/bin/nocap in runimage
        ${YELLOW}RIM_AUTORUN$GREEN=\"{executable} {args}\"        Run runimage with autorun options for /usr/bin executables
        ${YELLOW}RIM_ALLOW_ROOT$GREEN=1                         Allows to run runimage under root user
        ${YELLOW}RIM_QUIET_MODE$GREEN=1                         Disables all non-error runimage messages
        ${YELLOW}RIM_NO_WARN$GREEN=1                            Disables all warning runimage messages
        ${YELLOW}RIM_NOTIFY$GREEN=1                        Disables all non-error runimage notification
        ${YELLOW}RUNTIME_EXTRACT_AND_RUN$GREEN=1                Run runimage afer extraction without using FUSE
        ${YELLOW}TMPDIR$GREEN=\"/path/{TMPDIR}\"                Used for extract and run options
        ${YELLOW}RIM_CONFIG$GREEN=\"/path/{config}\"            runimage сonfiguration file (0 to disable)
        ${YELLOW}RIM_ENABLE_HOSTEXEC$GREEN=1                    Enables the ability to execute commands at the host level
        ${YELLOW}RIM_NO_RPIDSMON$GREEN=1                        Disables the monitoring thread of running processes
        ${YELLOW}RIM_SANDBOX_NET$GREEN=1                        Creates a network sandbox
        ${YELLOW}RIM_SNET_SHARE_HOST$GREEN=1                    Creates a network sandbox with access to host loopback
        ${YELLOW}RIM_SNET_CIDR$GREEN=11.22.33.0/24              Specifies tap interface subnet in network sandbox (Def: 10.0.2.0/24)
        ${YELLOW}RIM_SNET_TAPNAME$GREEN=tap0                    Specifies tap interface name in network sandbox (Def: eth0)
        ${YELLOW}RIM_SNET_MAC$GREEN=B6:40:E0:8B:A6:D7           Specifies tap interface MAC in network sandbox (Def: random)
        ${YELLOW}RIM_SNET_MTU$GREEN=65520                       Specifies tap interface MTU in network sandbox (Def: 1500)
        ${YELLOW}RIM_HOSTS_FILE$GREEN=\"file\"                  Binds specified file to /etc/hosts
        ${YELLOW}RIM_RESOLVCONF_FILE$GREEN=\"file\"             Binds specified file to /etc/resolv.conf
        ${YELLOW}RIM_BWRAP_ARGS$GREEN+=()                       Array with Bubblewrap arguments (for config file)
        ${YELLOW}RIM_EXEC_ARGS$GREEN+=()                        Array with Bubblewrap exec arguments (for config file)
        ${YELLOW}RIM_XORG_CONF$GREEN=\"/path/xorg.conf\"          Binds xorg.conf to /etc/X11/xorg.conf in runimage (0 to disable)
                                                (Default: /etc/X11/xorg.conf bind from the system)
        ${YELLOW}RIM_XEPHYR_SIZE$GREEN=\"HEIGHTxWIDTH\"           Sets runimage desktop resolution (Default: 1600x900)
        ${YELLOW}RIM_DESKTOP_DISPLAY$GREEN=\":9999\"               Sets runimage desktop ${YELLOW}\$DISPLAY$GREEN (Default: :1337)
        ${YELLOW}RIM_XEPHYR_FULLSCREEN$GREEN=1                  Starts runimage desktop in full screen mode
        ${YELLOW}RIM_DESKTOP_UNCLIP$GREEN=1                  Disables clipboard synchronization for runimage desktop

        ${YELLOW}RIM_SYS_TOOLS$GREEN=1                          Using all binaries from the system
                                             If they are not found in the system - auto return to the built-in

    ${RED}Other environment variables:
        ${GREEN}If inside RunImage:
            ${YELLOW}INSIDE_RUNIMAGE${GREEN}=1
        ${GREEN}RunImage path (for packed):
            ${YELLOW}RUNIMAGE${GREEN}=\"$RUNIMAGE\"
        ${GREEN}Squashfs offset (for packed):
            ${YELLOW}RUNOFFSET${GREEN}=\"$RUNOFFSET\"
        ${GREEN}Null argument:
            ${YELLOW}ARG0${GREEN}=\"$ARG0\"
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
            ${YELLOW}RUNSRCNAME${GREEN}=\"$RUNSRCNAME\"
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

    ${RED}Custom scripts and aliases:
        ${YELLOW}cip$GREEN                          Сheck public ip
        ${YELLOW}dbus-flmgr$GREEN                   Launch the system file manager via dbus
        ${YELLOW}nocap$GREEN                        Disables container capabilities
        ${YELLOW}sudo$GREEN                         Fake sudo (fakechroot fakeroot)
        ${YELLOW}pac$GREEN                          sudo pacman (fake sudo)
        ${YELLOW}packey$GREEN                       sudo pacman-key (fake sudo)
        ${YELLOW}panelipmon$GREEN                   Shows information about an active network connection
        ${YELLOW}rim-build$GREEN                     Starts the runimage build
        ${YELLOW}rim-desktop$GREEN                   Starts the desktop mode
        ${YELLOW}{xclipsync,xclipfrom}$GREEN        For clipboard synchronization in desktop mode
        ${YELLOW}webm2gif$GREEN                     Convert webm to gif
        ${YELLOW}transfer$GREEN                     Upload file to ${BLUE}https://transfer.sh
        ${YELLOW}rim-psmon$GREEN                     For monitoring of processes running in runimage containers
        ${YELLOW}hostexec$GREEN                     For execute commands at the host level (see ${YELLOW}RIM_ENABLE_HOSTEXEC$GREEN)
        ${YELLOW}rim-update$GREEN                    For runimage update

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
        The same principle applies to the ${YELLOW}RIM_AUTORUN$GREEN variable:
            $RED┌─[$GREEN$RUNUSER$YELLOW@$BLUE${RUNHOSTNAME}$RED]─[$GREEN$PWD$RED]
            $RED└──╼ \$ ${YELLOW}RIM_AUTORUN=\"ls -la\" ${GREEN}runimage ${YELLOW}{autorun executable args}${GREEN}
        Here runimage will become something like an alias for 'ls' in runimage
            with the '-la' argument. You can also use ${YELLOW}RIM_AUTORUN${GREEN} as an array for complex commands in the config.
            ${YELLOW}RIM_AUTORUN=(\"ls\" \"-la\" \"/path/to something\")${GREEN}
        This will also work in extracted form for the Run binary.

        When using the ${YELLOW}RIM_PORTABLE_HOME$GREEN and ${YELLOW}RIM_PORTABLE_CONFIG$GREEN variables, runimage will create or
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
            It can also be with the name of the executable file from ${YELLOW}RIM_AUTORUN$GREEN environment variables,
                or with the same name as the executable being run.
        ${YELLOW}RIM_SANDBOX_HOME$GREEN* similar to ${YELLOW}RIM_PORTABLE_HOME$GREEN, but the system ${YELLOW}HOME$GREEN becomes isolated.
        ${YELLOW}RIM_SANDBOX_HOME_DIR$GREEN and ${YELLOW}RIM_PORTABLE_HOME_DIR$GREEN point to a specific directory or create it in the absence of.

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
            It can also be with the name of the executable file from ${YELLOW}RIM_AUTORUN$GREEN environment variables,
                or with the same name as the executable being run.
            In ${YELLOW}\$RUNDIR$GREEN/config there are default configs in RunImage, they are run in priority,
                then external configs are run if they are found.

        ${RED}RunImage desktop:${GREEN}
            Ability to run RunImage in desktop mode. Default DE: XFCE (see rim-desktop)
            If the launch is carried out from an already running desktop, then Xephyr will start
                in windowed/full screen mode (see ${YELLOW}XEPHYR_*$GREEN environment variables)
                Use CTRL+SHIFT to grab the keyboard and mouse.
            It is also possible to run on TTY with Xorg (see ${YELLOW}RIM_XORG_CONF$GREEN environment variables)
                To do this, just log in to TTY and run RunImage desktop.
            ${RED}Important!${GREEN} The launch on the TTY should be carried out only under the user under whom the
                login to the TTY was carried out.

        ${RED}RunImage OverlayFS:${GREEN}
            Allows you to create additional separate layers to modify the container file system without
                changing the original container file system. Works packed and unpacked. Also, in packed form,
                it allows you to mount the container in RW mode.
            It also allows you to attach to the same OverlayFS when you specify its ID:
            $RED┌─[$GREEN$RUNUSER$YELLOW@$BLUE${RUNHOSTNAME}$RED]─[$GREEN$PWD$RED]
            $RED└──╼ \$ ${YELLOW}RIM_OVERFS_ID=1337 ${GREEN}runimage ${YELLOW}{args}${GREEN}
                If OverlayFS with such ID does not exist, it will be created.
            To save OverlayFS after closing the container, use ${YELLOW}RIM_KEEP_OVERFS:
            $RED┌─[$GREEN$RUNUSER$YELLOW@$BLUE${RUNHOSTNAME}$RED]─[$GREEN$PWD$RED]
            $RED└──╼ \$ ${YELLOW}RIM_KEEP_OVERFS=1 ${GREEN}runimage ${YELLOW}{args}${GREEN}
            To run a one-time OverlayFS, use ${YELLOW}RIM_OVERFS_MODE:
            $RED┌─[$GREEN$RUNUSER$YELLOW@$BLUE${RUNHOSTNAME}$RED]─[$GREEN$PWD$RED]
            $RED└──╼ \$ ${YELLOW}RIM_OVERFS_MODE=1 ${GREEN}runimage ${YELLOW}{args}${GREEN}

        ${RED}RunImage build:${GREEN}
            Allows you to create your own runimage containers.
            This works both externally by passing build args:
            $RED┌─[$GREEN$RUNUSER$YELLOW@$BLUE${RUNHOSTNAME}$RED]─[$GREEN$PWD$RED]
            $RED└──╼ \$ ${GREEN}runimage ${BLUE}rim-build ${YELLOW}{build args}${GREEN}
            And it also works inside the running instance (see rim-build):
            $RED┌─[$GREEN$RUNUSER$YELLOW@$BLUE${RUNHOSTNAME}$RED]─[$GREEN$PWD$RED] - in runimage
            $RED└──╼ \$ ${GREEN}rim-build ${YELLOW}{build args}${GREEN}
            Optionally, you can specify the following build arguments:
                ${YELLOW}{/path/new_runimage_name} {-zstd|-xz|-lz4} {zstd compression level 1-19}${GREEN}
            By default, runimage is created in the current directory with a standard name and
                with lz4 compression. If a new RunImage is successfully build, the old one is deleted.
                (see ${YELLOW}RIM_KEEP_OLD_BUILD${GREEN} ${YELLOW}RIM_BUILD_WITH_EXTENSION${GREEN} ${YELLOW}RIM_CMPRS_ALGO${GREEN} ${YELLOW}RIM_ZSDT_CMPRS_LVL${GREEN})

        ${RED}RunImage update:${GREEN}
            Allows you to update packages and rebuild RunImage. In unpacked form, automatic build will
                not be performed. When running an update, you can also pass arguments for a new build.
                (see RunImage build) (also see rim-update)
            $RED┌─[$GREEN$RUNUSER$YELLOW@$BLUE${RUNHOSTNAME}$RED]─[$GREEN$PWD$RED]
            $RED└──╼ \$ ${GREEN}runimage ${BLUE}rim-update ${YELLOW}{build args}${GREEN}
            By default, update and rebuild is performed in ${YELLOW}\$RUNIMAGEDIR${GREEN}

        ${RED}RunImage network sandbox:${GREEN}
            Allows you to create a private network namespace with slirp4netns and inside the container
                manage routing, create/delete network interfaces, connect to a vpn (checked openvpn
                and wireguard), configure your resolv.conf and hosts, etc. (see ${YELLOW}RIM_SANDBOX_NET${GREEN}*)
            By default, network sandbox created in 10.0.2.0/24 subnet, with eth0 tap name, 10.0.2.100 tap ip,
                1500 tap MTU, and random MAC.

        ${RED}RunImage hostexec:${GREEN}
            Allows you to run commands at the host level (see ${YELLOW}RIM_ENABLE_HOSTEXEC${GREEN} and hostexec)
            $RED┌─[$GREEN$RUNUSER$YELLOW@$BLUE${RUNHOSTNAME}$RED]─[$GREEN$PWD$RED]
            $RED└──╼ \$ ${YELLOW}RIM_ENABLE_HOSTEXEC${GREEN}=1 runimage ${BLUE}rim-shell ${GREEN}
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
            Checking the nvidia driver version can be disabled using ${YELLOW}RIM_NO_NVIDIA_CHECK$GREEN variable.
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
    $RESETCOLOR" >&2
}

trap cleanup EXIT

if [[ "$EUID" == 0 && "$RIM_ALLOW_ROOT" != 1 ]]
    then
        error_msg "root user is not allowed!"
        console_info_notify
        echo -e "${RED}\t\t\tDo not run RunImage as root!"
        echo -e "If you really need to run it as root set the ${YELLOW}RIM_ALLOW_ROOT${GREEN}=1 ${RED}environment variable.$RESETCOLOR"
        exit 1
fi

if [ -n "$RIM_AUTORUN" ] && \
   [[ "$RUNSRCNAME" == "Run"* || \
      "$RUNSRCNAME" == "runimage"* ]]
    then
        RUNSRCNAME=($RIM_AUTORUN)
elif [[ "${RUNSRCNAME,,}" =~ .*\.(runimage|rim)$ ]]
   then
        RUNSRCNAME="$(sed 's|\.runimage$||i;s|\.rim$||i'<<<"$RUNSRCNAME")"
        RIM_AUTORUN="$RUNSRCNAME"
elif [[ "$RUNSRCNAME" != "Run"* && \
        "$RUNSRCNAME" != "runimage"* ]]
   then
        RIM_AUTORUN="$RUNSRCNAME"
fi

ARGS=("$@")
if [[ -n "$1" && "$1" != 'rim-'* && ! -n "$RIM_AUTORUN" ]]
    then
        for arg in "${ARGS[@]}"
            do
                case "$arg" in
                    -*) : ;;
                    *)
                        export RUNSRCNAME="$(basename "$arg" 2>/dev/null)"
                        break
                    ;;
                esac
        done
        unset num
fi

ARG1="${ARGS[0]}"
if [[ -n "${ARGS[0]}" && "${ARGS[0]}" == 'rim-'* ]]
    then
        case "${ARGS[0]}" in
            rim-shrink|rim-dinteg) : ;;
            *) ARGS=("${ARGS[@]:1}") ;;
        esac
elif [[ "$RUNSRCNAME" == 'rim-'* ]]
    then ARG1="$RUNSRCNAME"
fi

case "$ARG1" in
    rim-psmon   ) set_default_option ; RIM_TMP_HOME=1
                    RIM_UNSHARE_PIDS=0 ; RIM_CONFIG=0
                    export SSRV_SOCK="unix:$RUNPIDDIR/rmp"
                    RIM_NO_RPIDSMON=1 ; RIM_QUIET_MODE=1
                    RIM_DESKTOP_INTEGRATION=0 ;;
    rim-kill   |\
    rim-help   |\
    rim-ofsls   ) NO_CRYPTFS_MOUNT=1 ; RIM_CONFIG=0
                  RIM_NO_RPIDSMON=1 ; RIM_DESKTOP_INTEGRATION=0
                  set_default_option ;;
esac

unset SET_RUNIMAGE_CONFIG SET_RUNIMAGE_INTERNAL_CONFIG
if [ "$RIM_CONFIG" != 0 ]
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
        if [[ -f "$RIM_CONFIG" && -n "$(echo "$RIM_CONFIG"|grep -o '\.rcfg$')" ]]
            then
                SET_RUNIMAGE_CONFIG=1
        elif [ -f "$RUNIMAGEDIR/$RUNSRCNAME.rcfg" ]
            then
                RIM_CONFIG="$RUNIMAGEDIR/$RUNSRCNAME.rcfg"
                SET_RUNIMAGE_CONFIG=1
        elif [ -f "$RUNCONFIGDIR/$RUNSRCNAME.rcfg" ]
            then
                RIM_CONFIG="$RUNCONFIGDIR/$RUNSRCNAME.rcfg"
                SET_RUNIMAGE_CONFIG=1
        elif [[ -n "$RUNIMAGE" && -f "$RUNIMAGE.rcfg" ]]
            then
                RIM_CONFIG="$RUNIMAGE.rcfg"
                SET_RUNIMAGE_CONFIG=1
        elif [ -f "$RUNIMAGEDIR/Run.rcfg" ]
            then
                RIM_CONFIG="$RUNIMAGEDIR/Run.rcfg"
                SET_RUNIMAGE_CONFIG=1
        elif [ -f "$RUNCONFIGDIR/Run.rcfg" ]
            then
                RIM_CONFIG="$RUNCONFIGDIR/Run.rcfg"
                SET_RUNIMAGE_CONFIG=1
        fi
        if [ "$SET_RUNIMAGE_CONFIG" == 1 ]
            then
                set -a
                source "$RIM_CONFIG"
                set +a
                info_msg "Found RunImage config: '$RIM_CONFIG'"
        fi
fi

export RUNCACHEDIR="${RIM_CACHEDIR:=$RUNIMAGEDIR/cache}"
export RUNOVERFSDIR="${RIM_OVERFSDIR:=$RUNIMAGEDIR/overlayfs}"

RUNUSER="$(logname 2>/dev/null)"
RUNUSER="${RUNUSER:=$SUDO_USER}"
RUNUSER="${RUNUSER:=$USER}"
RUNUSER="${RUNUSER:=$(id -un "$EUID" 2>/dev/null)}"

SSRV_ELF="$RUNSTATIC/ssrv"
CHISEL="$RUNSTATIC/chisel"

if [[ "$RIM_AUTORUN" == 'rim-'* ]]
    then
        case "$RIM_AUTORUN" in
            rim-shrink|rim-dinteg) : ;;
            *) ARG1="$RIM_AUTORUN"
               ARGS=("${RIM_AUTORUN[@]:1}" "${ARGS[@]}")
               unset RIM_AUTORUN ;;
        esac
fi

case "$ARG1" in
    rim-decfs     ) set_overfs_option crypt ;;
    rim-encfs  |\
    rim-enc-passwd) NO_CRYPTFS_MOUNT=1
                    set_overfs_option crypt ;;
    rim-pkgls  |\
    rim-binlist|\
    rim-version|\
    rim-build     ) set_default_option ;;
    rim-ofsrm     ) NO_CRYPTFS_MOUNT=1
                    set_default_option ;;
    rim-exec      ) if [ "$RIM_RUN_IN_ONE" != 1 ]
                        then run_attach exec "${ARGS[@]}" ; exit $?
                    fi ;;
    rim-portfw    ) if [ "$RIM_RUN_IN_ONE" != 1 ]
                        then run_attach portfw "${ARGS[@]}" ; exit $?
                    fi ;;
    rim-update    ) set_overfs_option upd ;;
    rim-desktop   ) export RIM_UNSHARE_DBUS=1 RIM_UNSHARE_PIDS=1
                    if [[ "$RUNTTY" =~ "tty" && ! "${ARGS[0]}" =~ ^(-h|--help)$ ]]
                        then
                            if [ "$EUID" != 0 ] && ! grep -q "^input:.*[:,]$RUNUSER$\|^input:.*[:,]$RUNUSER," /etc/group
                                then
                                    error_msg "The user is not a member of the input group!"
                                    console_info_notify
                                    echo -e "${YELLOW}Make sure to add yourself to the input group:"
                                    echo -e "${RED}# ${GREEN}sudo gpasswd -a $RUNUSER input && logout$RESETCOLOR"
                                    exit 1
                            fi
                            export RIM_FORCE_KILL_PPID=1
                    fi ;;
esac

if [ "$RIM_RUN_IN_ONE" == 1 ]
    then
        RUNIMAGEDIR_SUM=($(sha1sum<<<"$RUNIMAGEDIR"))
        SSRV_SOCK_PATH="$RUNPIDDIR/${RUNIMAGEDIR_SUM}.sock"
        SSRV_RUNPID="$(ls -1 "$RUNTMPDIR"/*/"${RUNIMAGEDIR_SUM}.sock" 2>/dev/null|awk -F'/' 'NR==1{print $(NF-1)}')"
        if [ -n "$SSRV_RUNPID" ]
            then
                if is_pid "$SSRV_RUNPID"
                    then
                        RUNPORTFW="${RUNTMPDIR}/${SSRV_RUNPID}/portfw"
                        SSRV_SOCK_PATH="${RUNTMPDIR}/${SSRV_RUNPID}/${RUNIMAGEDIR_SUM}.sock"
                    else rm -f "${RUNTMPDIR}/${SSRV_RUNPID}.${RUNIMAGEDIR_SUM}.sock"
                fi
        fi
        export SSRV_SOCK="unix:$SSRV_SOCK_PATH"
        if [ -e "$SSRV_SOCK_PATH" ]
            then
                case "$ARG1" in
                    rim-portfw ) run_attach portfw "$SSRV_RUNPID" "${ARGS[@]}" ;;
                    *) run_attach exec "$SSRV_RUNPID" "${ARGS[@]}" ;;
                esac
        fi
fi

mkdir -p "$RUNPIDDIR"
chmod go-rwx "$REUIDDIR"/{,/run}

export RUNUSER
export EGID="$(id -g 2>/dev/null)"
export RUNGROUP="$(id -gn 2>/dev/null)"

if [[ "$DISPLAY" == "wayland-"* ]]
    then
        export DISPLAY=":${DISPLAY/wayland-/}"
elif [[ ! -n "$DISPLAY" && ! -n "$WAYLAND_DISPLAY" && -n "$XDG_SESSION_TYPE" ]]
    then
        export DISPLAY="$(who|grep "$RUNUSER"|grep -v "ttyS"|\
                          grep -om1 '(.*)$'|sed 's/(//;s/)//')"
fi

xhost +si:localuser:$RUNUSER &>/dev/null
[[ "$EUID" == 0 && "$RUNUSER" != "root" ]] && \
    xhost +si:localuser:root &>/dev/null

ulimit -n $(ulimit -n -H) &>/dev/null

runbinds=()
DEF_MOUNTS_BIND=()
if [ "$RIM_UNSHARE_DEF_MOUNTS" != 1 ]
    then
        DEF_MOUNTS_BIND+=(
            '--bind-try' '/mnt' '/mnt'
            '--bind-try' '/media' '/media'
        )
        [ "$RIM_UNSHARE_RUN" != 1 ] && \
            runbinds+=("/run/media")
    else
        warn_msg "Default mount points are unshared!"
fi

RUNXDGRUNTIME="/run/user/$EUID"
[[ ! -n "$XDG_RUNTIME_DIR" && -d "$RUNXDGRUNTIME" ]] && \
    export XDG_RUNTIME_DIR="$RUNXDGRUNTIME"
XDG_RUN_BIND=(
    "--tmpfs" "/run"
    "--chmod" "0775" "/run"
    "--dir" "$RUNXDGRUNTIME"
    "--tmpfs" "$RUNXDGRUNTIME"
    "--chmod" "0700" "$RUNXDGRUNTIME"
    "--setenv" "XDG_RUNTIME_DIR" "$RUNXDGRUNTIME"
)

UNSHARE_BIND=()
if [ "$RIM_UNSHARE_PIDS" == 1 ]
    then
        warn_msg "Host PIDs are unshared!"
        UNSHARE_BIND+=("--unshare-pid" "--as-pid-1")
fi
if [ "$RIM_UNSHARE_DBUS" == 1 ]
    then
        warn_msg "Host DBUS is unshared!"
        UNSHARE_BIND+=("--unsetenv" "DBUS_SESSION_BUS_ADDRESS")
fi
if [ "$RIM_UNSHARE_RUN" == 1 ]
    then
        warn_msg "Host RUN is unshared!"
        [[ "$DBUS_SESSION_BUS_ADDRESS" =~ /run/* ]] && \
        UNSHARE_BIND+=("--unsetenv" "DBUS_SESSION_BUS_ADDRESS")
    else
        [ "$RIM_UNSHARE_UDEV" != 1 ] && \
            runbinds+=("/run/udev")||\
            warn_msg "Host UDEV is unshared!"

        XDGRUN_UNSHARE=()
        if [[ "$RIM_SHARE_SYSTEMD" == 1 && -d "/run/systemd" ]]
            then
                warn_msg "Host SystemD is shared!"
                runbinds+=("/run/systemd")
                [[ "$XDG_RUNTIME_DIR" == "$RUNXDGRUNTIME" ]] && \
                    runbinds+=("$XDG_RUNTIME_DIR/systemd")||\
                    XDG_RUN_BIND+=("--bind-try" "$XDG_RUNTIME_DIR/systemd" "$RUNXDGRUNTIME/systemd")
            else
                XDGRUN_UNSHARE+=("$XDG_RUNTIME_DIR/systemd")
        fi

        XDGRUN_DBUS=()
        XDGRUN_SOUND=()
        if [ -d "$XDG_RUNTIME_DIR" ]
            then
                XDGRUN_DBUS+=(
                    "$XDG_RUNTIME_DIR/bus"
                    "$XDG_RUNTIME_DIR/dbus-1"
                )
                XDGRUN_SOUND+=(
                    "$XDG_RUNTIME_DIR/pulse"
                    "$XDG_RUNTIME_DIR/pipewire-0"
                    "$XDG_RUNTIME_DIR/pipewire-0.lock"
                    "$XDG_RUNTIME_DIR/pipewire-0-manager"
                    "$XDG_RUNTIME_DIR/pipewire-0-manager.lock"
                )
        fi

        if [[ -n "$XDGRUN_SOUND" && "$RIM_UNSHARE_XDGSOUND" == 1 ]]
            then
                warn_msg "Host XDG sound sockets are unshared!"
                XDGRUN_UNSHARE+=("${XDGRUN_SOUND[@]}")
        fi

        [ "$RIM_UNSHARE_DBUS" != 1 ] && \
            runbinds+=("/run/dbus")

        [ "$RIM_UNSHARE_PIDS" != 1 ] && \
            runbinds+=("/run/utmp")

        if [ "$RIM_UNSHARE_XDGRUN" == 1 ]
            then warn_msg "Host XDG_RUNTIME_DIR is unshared!"
            else
                if [ "$RIM_UNSHARE_PIDS" == 1 ]
                    then
                        if [ "$RIM_UNSHARE_DBUS" != 1 ]
                            then
                                [[ "$XDG_RUNTIME_DIR" == "$RUNXDGRUNTIME" ]] && \
                                    runbinds+=(
                                        "${XDGRUN_DBUS[@]}"
                                    )||\
                                    for item in "${XDGRUN_DBUS[@]}"
                                        do XDG_RUN_BIND+=("--bind-try" "$item" "${item/"$XDG_RUNTIME_DIR"/"$RUNXDGRUNTIME"}")
                                    done
                        fi
                        if [ "$RIM_UNSHARE_XDGSOUND" != 1 ]
                            then
                                [[ "$XDG_RUNTIME_DIR" == "$RUNXDGRUNTIME" ]] && \
                                    runbinds+=(
                                        "${XDGRUN_SOUND[@]}"
                                    )||\
                                    for item in "${XDGRUN_SOUND[@]}"
                                        do XDG_RUN_BIND+=("--bind-try" "$item" "${item/"$XDG_RUNTIME_DIR"/"$RUNXDGRUNTIME"}")
                                    done
                        fi
                    else
                        [ "$RIM_UNSHARE_DBUS" == 1 ] && \
                            XDGRUN_UNSHARE+=("${XDGRUN_DBUS[@]}")
                fi

                if [[ "$RIM_UNSHARE_PIDS" != 1 && -d "$XDG_RUNTIME_DIR" ]]
                    then
                        for runbind in "$XDG_RUNTIME_DIR"/* "$XDG_RUNTIME_DIR"/.*
                            do
                                if [[ -e "$runbind" && ! "${XDGRUN_UNSHARE[@]}" =~ "$runbind" ]]
                                    then
                                        [[ "$XDG_RUNTIME_DIR" == "$RUNXDGRUNTIME" ]] && \
                                            runbinds+=("$runbind")||\
                                            XDG_RUN_BIND+=("--bind-try" "$runbind" "${runbind/"$XDG_RUNTIME_DIR"/"$RUNXDGRUNTIME"}")
                                fi
                        done
                fi
        fi
fi
for bind in "${runbinds[@]}"
    do XDG_RUN_BIND+=("--bind-try" "$bind" "$bind")
done

LOCALTIME_BIND=()
if [ "$RIM_UNSHARE_LOCALTIME" != 1 ]
    then LOCALTIME_BIND+=("--ro-bind-try" "/etc/localtime" "/etc/localtime")
    else warn_msg "Host '/etc/localtime' is unshared!"
fi

if [ "$RIM_NO_RPIDSMON" != 1 ]
    then
        RPIDSFL="$RUNPIDDIR/rpids"
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
                        if [[ -n "$(echo -e "$newrpids\n$oldrpids"|\
                            sort -n|uniq -u)" || ! -f "$RPIDSFL" ]]
                            then
                                [ -d "$(dirname "$RPIDSFL")" ] && \
                                echo "$newrpids" > "$RPIDSFL"
                                oldrpids="$newrpids"
                        fi
                fi
                sleep 0.5 2>/dev/null
        done) &
fi

if [[ ! -n "$DBUS_SESSION_BUS_ADDRESS" && "$RIM_UNSHARE_DBUS" != 1 ]]
    then
        if [ -S "$XDG_RUNTIME_DIR/bus" ]
            then export DBUS_SESSION_BUS_ADDRESS="unix:path=$XDG_RUNTIME_DIR/bus"
        elif get_dbus_session_bus_address &>/dev/null
            then export $(get_dbus_session_bus_address)
        fi
fi

[ "$RIM_SYS_TOOLS" == 1 ] && \
    SYS_MKSQFS=1 SYS_GOCRYPTFS=1 \
    SYS_SQFUSE=1 SYS_BWRAP=1 \
    SYS_UNIONFS=1 SYS_SLIRP=1 \

if [ "$SYS_MKSQFS" == 1 ] && is_sys_exe mksquashfs
    then
        info_msg "The system mksquashfs is used!"
        MKSQFS="$(which_sys_exe mksquashfs)"
    else
        MKSQFS="$RUNSTATIC/mksquashfs"
fi
if [ "$SYS_SLIRP" == 1 ] && is_sys_exe slirp4netns
    then
        info_msg "The system slirp4netns is used!"
        SLIRP="$(which_sys_exe slirp4netns)"
    else
        SLIRP="$RUNSTATIC/slirp4netns"
fi
if [ "$SYS_SQFUSE" == 1 ] && is_sys_exe squashfuse
    then
        info_msg "The system squashfuse is used!"
        SQFUSE="$(which_sys_exe squashfuse)"
    else
        SQFUSE="$RUNSTATIC/squashfuse"
fi
if [ "$SYS_UNIONFS" == 1 ] && is_sys_exe unionfs
    then
        info_msg "The system unionfs is used!"
        UNIONFS="$(which_sys_exe unionfs)"
    else
        UNIONFS="$RUNSTATIC/unionfs"
fi
if [ "$SYS_GOCRYPTFS" == 1 ] && is_sys_exe gocryptfs
    then
        info_msg "The system gocryptfs is used!"
        GOCRYPTFS="$(which_sys_exe gocryptfs)"
    else
        GOCRYPTFS="$RUNSTATIC/gocryptfs"
fi

TMP_PATH_DIR='/tmp/.path'
[ -d "$TMP_PATH_DIR" ] && \
export PATH="$PATH:$TMP_PATH_DIR"
for fusermount in fusermount fusermount3
    do
        [[ "$fusermount" == *3 ]] && \
            fallback='fusermount'||\
            fallback='fusermount3'
        if ! is_exe_exist "$fusermount"
            then
                fusermount_path="$(which_sys_exe "$fallback")"
                if [ -n "$fusermount_path" ]
                    then
                        mkdir -p "$TMP_PATH_DIR"
                        ln -sf "$fusermount_path" "$TMP_PATH_DIR/$fusermount"
                        export PATH="$PATH:$TMP_PATH_DIR"
                        break
                fi
        fi
done

if [ "$EUID" != 0 ]
    then
        if [ ! -f '/proc/self/ns/user' ]
            then
                SYS_BWRAP=1
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
                        exit 1
                fi
        elif [ "$(cat '/proc/sys/kernel/unprivileged_userns_clone' 2>/dev/null)" == 0 ]
            then
                error_msg "unprivileged_userns_clone is disabled!"
                console_info_notify
                echo -e "${YELLOW}You need to enable unprivileged_userns_clone:"
                echo -e "${RED}# ${GREEN}sudo tee /etc/sysctl.d/98-unprivileged-userns-clone.conf <<<kernel.unprivileged_userns_clone=1"
                echo -e "${RED}# ${GREEN}sudo tee /proc/sys/kernel/unprivileged_userns_clone <<<1$RESETCOLOR"
                exit 1
        elif [ "$(cat '/proc/sys/user/max_user_namespaces' 2>/dev/null)" == 0 ]
            then
                error_msg "max_user_namespaces is disabled!"
                console_info_notify
                echo -e "${YELLOW}You need to enable max_user_namespaces:"
                echo -e "${RED}# ${GREEN}sudo tee /etc/sysctl.d/98-max-user-namespaces.conf <<<user.max_user_namespaces=10000"
                echo -e "${RED}# ${GREEN}sudo tee /proc/sys/user/max_user_namespaces <<<10000$RESETCOLOR"
                exit 1
        elif [ "$(cat '/proc/sys/kernel/userns_restrict' 2>/dev/null)" == 1 ]
            then
                error_msg "userns_restrict is enabled!"
                console_info_notify
                echo -e "${YELLOW}You need to disable userns_restrict:"
                echo -e "${RED}# ${GREEN}sudo tee /etc/sysctl.d/98-userns.conf <<<kernel.userns_restrict=0"
                echo -e "${RED}# ${GREEN}sudo tee /proc/sys/kernel/userns_restrict <<<0$RESETCOLOR"
                exit 1
        elif [ "$(cat '/proc/sys/kernel/apparmor_restrict_unprivileged_userns' 2>/dev/null)" == 1 ]
            then
                error_msg "apparmor_restrict_unprivileged_userns is enabled!"
                console_info_notify
                echo -e "${YELLOW}You need to disable apparmor_restrict_unprivileged_userns:"
                echo -e "${RED}# ${GREEN}sudo tee /etc/sysctl.d/98-apparmor-unuserns.conf <<<kernel.apparmor_restrict_unprivileged_userns=0"
                echo -e "${RED}# ${GREEN}sudo tee /proc/sys/kernel/apparmor_restrict_unprivileged_userns <<<0$RESETCOLOR"
                exit 1
        fi
fi

if [ "$SYS_BWRAP" == 1 ] && is_sys_exe bwrap
    then
        info_msg "The system Bubblewrap is used!"
        BWRAP="$(which_sys_exe bwrap)"
    else
        BWRAP="$RUNSTATIC/bwrap"
fi
unset SUID_BWRAP
if [[ "$SYS_BWRAP" == 1 && "$EUID" != 0 && \
      -x "$(find "$BWRAP" -perm -u=s 2>/dev/null)" ]]
    then
        warn_msg "Bubblewrap has SUID sticky bit!"
        SUID_BWRAP=1
fi
if [[ "$SUID_BWRAP" == 1 || "$RIM_NO_CAP" == 1 ]]
    then
        warn_msg "Bubblewrap capabilities is disabled!"
        BWRAP_CAP=("--cap-drop" "ALL")
    else
        BWRAP_CAP=("--cap-add" "ALL" "${BWRAP_CAP[@]}")
        BWRAP_CAP+=("--cap-drop" "CAP_SYS_NICE") # Gamecope bug https://github.com/Plagman/gamescope/issues/309
fi

[ "$(getenforce 2>/dev/null)" == "Enforcing" ] && \
    warn_msg "SELinux in enforcing mode!"

[[ ! -n "$RUNIMAGE" && -w "$RUNIMAGEDIR" ]] && \
    CRYPTFS_MNT="$RUNIMAGEDIR/rootfs" ||\
    CRYPTFS_MNT="$RUNPIDDIR/mnt/rootfs"
CRYPTFS_DIR="$RUNDIR/cryptfs"

unset OVERFS_MNT OVERFS_DIR BOVERLAY_SRC
if [ "$RIM_OVERFS_MODE" != 0 ] && [[ "$RIM_OVERFS_MODE" == 1 || "$RIM_KEEP_OVERFS" == 1 || -n "$RIM_OVERFS_ID" ]]
    then
        if [ ! -n "$RIM_OVERFS_ID" ]
            then
                export RIM_OVERFS_ID=0
                while true
                    do
                        [ ! -d "$RUNOVERFSDIR/$RIM_OVERFS_ID" ] && \
                            break
                        export RIM_OVERFS_ID="$(( $RIM_OVERFS_ID + 1 ))"
                done
        fi
        if [[ -n "$RIM_OVERFS_ID" && -d "$RUNOVERFSDIR/$RIM_OVERFS_ID" ]]
            then
                [ "$RIM_KEEP_OVERFS" != 0 ] && \
                    RIM_KEEP_OVERFS=1
                info_msg "Attaching to OverlayFS: $RIM_OVERFS_ID"
            else
                info_msg "OverlayFS ID: $RIM_OVERFS_ID"
        fi
        export OVERFS_DIR="$RUNOVERFSDIR/$RIM_OVERFS_ID"
        try_mkdir "$OVERFS_DIR"
        UNIONFS_ARGS=(
            -f -o max_files=$(ulimit -n -H),nodev,hide_meta_files,cow,noatime,nodev
            -o uid=$EUID,gid=${EGID}$([ "$EUID" != 0 ] && echo ,relaxed_permissions)
        )
        mkdir -p "$OVERFS_DIR"/{layers,mnt}
        [ -e "$OVERFS_DIR/layers/rootfs/.decfs" ] && \
            export RIM_NO_BWRAP_OVERLAY=1
        if ! is_cryptfs && [ "$RIM_NO_BWRAP_OVERLAY" != 1 ]
            then
                try_mkdir "$OVERFS_DIR/workdir"
                try_mkdir "$OVERFS_DIR/bwrap/rootfs"
                UNIONFS_ARGS+=(-o dirs="$OVERFS_DIR/layers"=RW:"$OVERFS_DIR/bwrap"=RW:"$RUNDIR"=RO)
                BOVERLAY_SRC="$RUNROOTFS"
            else
                warn_msg "Bubblewrap OverlayFS is disabled!"
                UNIONFS_ARGS+=(-o dirs="$OVERFS_DIR/layers"=RW:"$RUNDIR"=RO)
        fi
        [ ! -L "$OVERFS_DIR/RunDir" ] && \
        ln -sfr "$OVERFS_DIR/mnt" "$OVERFS_DIR/RunDir"
        export OVERFS_MNT="$OVERFS_DIR/mnt"
        BRUNDIR="$OVERFS_MNT"
        "$UNIONFS" "${UNIONFS_ARGS[@]}" "$OVERFS_MNT" &>/dev/null &
        UNIONFS_PID="$!"
        FUSE_PIDS="$UNIONFS_PID $FUSE_PIDS"
        if ! mount_exist "$UNIONFS_PID" "$OVERFS_MNT"
            then
                error_msg "Failed to mount RunImage in OverlayFS mode!"
                cleanup force
                exit 1
        fi
        export RUNROOTFS="$OVERFS_MNT/rootfs"
        CRYPTFS_MNT="$OVERFS_DIR/rootfs"
        CRYPTFS_DIR="$OVERFS_MNT/cryptfs"
fi

CRYPTFS_ARGS=("$GOCRYPTFS" "$CRYPTFS_DIR" "$CRYPTFS_MNT" '--nosyslog')
if [ ! -n "$CRYPTFS_PASSFILE" ]
    then
        if [ -f "$RUNIMAGEDIR/passfile" ]
            then CRYPTFS_PASSFILE="$RUNIMAGEDIR/passfile"
        elif [ -f "$RUNDIR/passfile" ]
            then CRYPTFS_PASSFILE="$RUNDIR/passfile"
        fi
fi
if [ -f "$CRYPTFS_PASSFILE" ]
    then
        info_msg "GoCryptFS passfile: '$CRYPTFS_PASSFILE'"
        CRYPTFS_ARGS+=("--passfile" "$CRYPTFS_PASSFILE")
    else unset CRYPTFS_PASSFILE
fi

unset KEEP_CRYPTFS
if is_cryptfs && [ "$NO_CRYPTFS_MOUNT" != 1 ]
    then
        export RIM_ZSDT_CMPRS_LVL=1
        try_mkdir "$CRYPTFS_MNT"
        if [ ! -n "$(ls -A "$CRYPTFS_MNT" 2>/dev/null)" ]
            then
                info_msg "Mounting RunImage rootfs in GoCryptFS mode..."
                if [ -f "$CRYPTFS_PASSFILE" ]
                    then
                        unset encfifo
                        "${CRYPTFS_ARGS[@]}" -fg &
                    else
                        encfifo="$RUNPIDDIR/encfifo"
                        mkfifo "$encfifo"
                        exec 7<>"$encfifo"
                        rm -f "$encfifo"
                        "${CRYPTFS_ARGS[@]}" -fg <&7 &
                fi
                CRYPTFS_PID="$!"
                if [ -n "$encfifo" ]
                    then
                        read -s -r encpass && echo "$encpass">&7
                        unset encpass
                        exec 7>&-
                fi
                if ! mount_exist "$CRYPTFS_PID" "$CRYPTFS_MNT"
                    then
                        error_msg "Failed to mount RunImage rootfs in GoCryptFS mode!"
                        cleanup force
                        exit 1
                fi
                FUSE_PIDS="$CRYPTFS_PID $FUSE_PIDS"
            else
                info_msg "Attaching to GoCryptFS rootfs..."
                KEEP_CRYPTFS=1
        fi
        [ -d "$OVERFS_DIR" ] && \
        export RIM_NO_BWRAP_OVERLAY=1
        export RUNROOTFS="$CRYPTFS_MNT"
        export CRYPTFS_DIR
        export CRYPTFS_MNT
        export_rootfs_info
fi

[[ -d "$BRUNDIR" && "$OVERFS_MNT" == "$BRUNDIR" ]]||\
    BRUNDIR="$RUNDIR"
RUNDIR_BIND=(
    "--bind-try" "$BRUNDIR" "/var/RunDir"
    "--setenv" "RUNDIR" "/var/RunDir"
    "--setenv" "RUNUTILS" "/var/RunDir/utils"
    "--setenv" "RUNSTATIC" "/var/RunDir/static"
    "--setenv" "RUNROOTFS" "/var/RunDir/rootfs"
    "--setenv" "RUNRUNTIME" "/var/RunDir/static/uruntime"
)

TMP_BIND=()
if [[ -d "/tmp/.X11-unix" && "$RIM_UNSHARE_TMP" != 1 ]]
    then
        if [  "$RIM_UNSHARE_TMPX11UNIX" != 1 ] # Gamecope X11 sockets bug
            then
                if [ -L "/tmp/.X11-unix" ] # WSL
                    then
                        TMP_BIND+=("--tmpfs" "/tmp" "--dir" "/tmp/.X11-unix")
                        for i_tmp in /tmp/* /tmp/.[a-zA-Z0-9]*
                            do
                                [ "$i_tmp" != "/tmp/.X11-unix" ] && \
                                    TMP_BIND+=("--bind-try" "$i_tmp" "$i_tmp")
                        done
                    else
                        check_unshare_tmp
                        TMP_BIND+=("--tmpfs" "/tmp/.X11-unix")
                fi
                if [ -n "$(ls -A /tmp/.X11-unix 2>/dev/null)" ]
                    then
                        for x_socket in /tmp/.X11-unix/X*
                            do TMP_BIND+=("--bind-try" "$x_socket" "$x_socket")
                        done
                fi
            else
                warn_msg "Host /tmp/.X11-unix is unshared!"
                check_unshare_tmp
                TMP_BIND+=("--tmpfs" "/tmp/.X11-unix")
        fi
    else check_unshare_tmp
fi

TMPDIR_BIND=()
if [ -d "$TMPDIR" ]
    then
        NEWTMPDIR="$RUNPIDDIR/tmp"
        info_msg "Bind \$TMPDIR to: '$NEWTMPDIR'"
        TMPDIR_BIND+=(
            "--dir" "$NEWTMPDIR"
            "--bind-try" "$TMPDIR" "$NEWTMPDIR"
            "--setenv" "TMPDIR" "$NEWTMPDIR"
        )
    else
        unset TMPDIR
fi

add_bin_pth "$HOME/.local/bin:/bin:/sbin:/usr/bin:/usr/sbin:\
/usr/lib/jvm/default/bin:/usr/local/bin:/usr/local/sbin:\
/opt/cuda/bin:$HOME/.cargo/bin:$SYS_PATH:/usr/bin/vendor_perl:\
/var/RunDir/static:/var/RunDir/utils"
[ -n "$LD_LIBRARY_PATH" ] && \
    add_lib_pth "$LD_LIBRARY_PATH"

if [ -n "$RIM_AUTORUN" ]
    then
        AUTORUN0ARG=($RIM_AUTORUN)
        info_msg "Autorun mode: ${RIM_AUTORUN[@]}"
        if RIM_QUIET_MODE=1 RIM_SANDBOX_NET=0 bwrun \
            which "$AUTORUN0ARG" &>/dev/null
            then
                export RUNSRCNAME="$AUTORUN0ARG"
            else
                error_msg "$AUTORUN0ARG not found in PATH!"
                cleanup force
                exit 1
        fi
fi

SETENV_ARGS=()
if [ ! -n "$RIM_SHELL" ]
    then
        if [ -x "$RUNROOTFS/usr/bin/fish" ]
            then
                RIM_SHELL='/usr/bin/fish'
        elif [ -x "$RUNROOTFS/usr/bin/zsh" ]
            then
                RIM_SHELL='/usr/bin/zsh'
        elif [ -x "$RUNROOTFS/usr/bin/bash" ]
            then
                RIM_SHELL=('/usr/bin/bash' '--rcfile' '/etc/bash.bashrc')
        elif [ -x "$RUNROOTFS/usr/bin/sh" ]
            then
                RIM_SHELL='/usr/bin/sh'
        fi
fi
SETENV_ARGS+=("--setenv" "SHELL" "$RIM_SHELL")

[ -n "$HOME" ] && \
SYS_HOME="$HOME"||\
unset SYS_HOME

if [[ "$RIM_SANDBOX_HOME" != 0 && "$RIM_SANDBOX_HOME_DL" != 0 ]]
    then
        [[ -n "$RIM_SANDBOX_HOME_DIR" && ! -d "$RIM_SANDBOX_HOME_DIR" ]] && \
            try_mkhome "$RIM_SANDBOX_HOME_DIR"
        if [ ! -d "$RIM_SANDBOX_HOME_DIR" ]
            then
                if [ -d "$SANDBOXHOMEDIR/$RUNSRCNAME" ]
                    then RIM_SANDBOX_HOME_DIR="$SANDBOXHOMEDIR/$RUNSRCNAME"
                elif [[ -n "$RUNIMAGE" && -d "$SANDBOXHOMEDIR/$RUNIMAGENAME" ]]
                    then RIM_SANDBOX_HOME_DIR="$SANDBOXHOMEDIR/$RUNIMAGENAME"
                elif [ -d "$SANDBOXHOMEDIR/Run" ]
                    then RIM_SANDBOX_HOME_DIR="$SANDBOXHOMEDIR/Run"
                fi
        fi
    else unset RIM_SANDBOX_HOME_DIR
fi

unset HOME_BIND SET_HOME_DIR NEW_HOME
if [[ "$RIM_TMP_HOME" == 1 || "$RIM_TMP_HOME_DL" == 1 ]]
    then
        [ "$EUID" == 0 ] && \
            TMP_HOME="/root" || \
            TMP_HOME="/home/$RUNUSER"
        HOME_BIND+=(
            "--tmpfs" "/home"
            "--tmpfs" "/root"
            "--dir" "$TMP_HOME/.cache"
            "--dir" "$TMP_HOME/.config"
        )
        [[ "$EUID" == 0 && "$RUNUSER" != "root" ]] && \
            HOME_BIND+=("--dir" "/home/$RUNUSER")
        [ "$RIM_TMP_HOME_DL" == 1 ] && \
            HOME_BIND+=(
                "--dir" "$TMP_HOME/Downloads"
                "--symlink" "Downloads" "$TMP_HOME/Загрузки"
                "--bind-try" "$SYS_HOME/Downloads" "$TMP_HOME/Downloads"
            )
        HOME_BIND+=('--setenv' 'HOME' "$TMP_HOME")
        info_msg "Setting temporary \$HOME to: '$TMP_HOME'"
elif [[ "$RIM_UNSHARE_HOME" == 1 || "$RIM_UNSHARE_HOME_DL" == 1 ]]
    then
        [ "$EUID" == 0 ] && \
            UNSHARED_HOME="/root" || \
            UNSHARED_HOME="/home/$RUNUSER"
        if [ -w "$RUNROOTFS" ]
            then
                if [ "$EUID" != 0 ]
                    then
                        [ ! -d "$RUNROOTFS/home/runimage" ] && \
                            HOME_BIND+=('--dir' '/home/runimage')
                        [[ ! -d "$RUNROOTFS/$UNSHARED_HOME" && ! -L "$RUNROOTFS/$UNSHARED_HOME" ]] && \
                            HOME_BIND+=('--symlink' 'runimage' "$UNSHARED_HOME")
                fi
                HOME_BIND+=(
                    '--dir' "$UNSHARED_HOME/.cache"
                    '--dir' "$UNSHARED_HOME/.config"
                )
                [ "$RIM_UNSHARE_HOME_DL" == 1 ] && \
                    HOME_BIND+=(
                        "--dir" "$UNSHARED_HOME/Downloads"
                        "--symlink" "Downloads" "$UNSHARED_HOME/Загрузки"
                        "--bind-try" "$HOME/Downloads" "$UNSHARED_HOME/Downloads"
                    )
            else
                if [[ "$EUID" != 0 && ! -d "$RUNROOTFS/$UNSHARED_HOME" && \
                    ! -L "$RUNROOTFS/$UNSHARED_HOME" && "$NO_CRYPTFS_MOUNT" != 1 ]]
                    then
                        warn_msg "The user HOME directory not found in the container!"
                        if [ -d "$RUNROOTFS/home/runimage" ]
                            then
                                warn_msg "Fallback HOME to: /home/runimage"
                                UNSHARED_HOME="/home/runimage"
                            else
                                error_msg "Fallback HOME directory /home/runimage not found in the container!"
                                cleanup force
                                exit 1
                        fi
                fi
                if [ "$RIM_UNSHARE_HOME_DL" == 1 ]
                    then
                        if [ ! -d "$RUNROOTFS/$UNSHARED_HOME/Downloads" ]
                            then warn_msg "Unable to bind Downloads directory!"
                            else HOME_BIND+=("--bind-try" "$SYS_HOME/Downloads" "$UNSHARED_HOME/Downloads")
                        fi
                fi
        fi
        HOME_BIND+=('--setenv' 'HOME' "$UNSHARED_HOME")
        warn_msg "Host HOME is unshared!"
elif [[ "$RIM_SANDBOX_HOME" == 1 || "$RIM_SANDBOX_HOME_DL" == 1 || -d "$RIM_SANDBOX_HOME_DIR" ]]
    then
        if [ "$EUID" == 0 ]
            then NEW_HOME="/root"
            else
                NEW_HOME="/home/$RUNUSER"
                HOME_BIND+=(
                    "--tmpfs" "/home"
                    "--dir" "$NEW_HOME"
                )
        fi
        [ ! -n "$RIM_SANDBOX_HOME_DIR" ] && \
            RIM_SANDBOX_HOME_DIR="$SANDBOXHOMEDIR/$RUNSRCNAME"
        if [[ "$RIM_SANDBOX_HOME" == 1 || "$RIM_SANDBOX_HOME_DL" == 1 ]] && \
            [ ! -d "$RIM_SANDBOX_HOME_DIR" ]
            then
                RIM_SANDBOX_HOME_DIR="$SANDBOXHOMEDIR/$RUNSRCNAME"
                try_mkhome "$RIM_SANDBOX_HOME_DIR"
        fi
        HOME_BIND+=("--bind-try" "$RIM_SANDBOX_HOME_DIR" "$NEW_HOME")
        [ "$RIM_SANDBOX_HOME_DL" == 1 ] && \
            HOME_BIND+=(
                "--dir" "$NEW_HOME/Downloads"
                "--symlink" "Downloads" "$NEW_HOME/Загрузки"
                "--bind-try" "$SYS_HOME/Downloads" "$NEW_HOME/Downloads"
            )
        HOME_BIND+=("--setenv" "HOME" "$NEW_HOME")
        info_msg "Setting sandbox \$HOME to: '$RIM_SANDBOX_HOME_DIR'"
else
    if [[ -n "$SYS_HOME" && "$SYS_HOME" != "/root" && \
        "$(echo "$SYS_HOME"|head -c 6)" != "/home/" ]]
        then
            case "$(cut -d '/' -f2<<<"$SYS_HOME")" in
                tmp|mnt|media|run|dev|proc|sys) : ;;
                *)
                    if [ "$EUID" == 0 ]
                        then
                            NEW_HOME="/root"
                            HOME_BIND+=("--bind-try" "/home" "/home")
                        else
                            NEW_HOME="/home/$RUNUSER"
                            HOME_BIND+=(
                                "--tmpfs" "/home"
                                "--tmpfs" "/root"
                                "--dir" "$NEW_HOME"
                            )
                    fi
                    HOME_BIND+=(
                        "--bind-try" "$SYS_HOME" "$NEW_HOME"
                        "--setenv" "HOME" "$NEW_HOME"
                    )
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
    if [ "$RIM_PORTABLE_HOME" != 0 ]
        then
            [[ -n "$RIM_PORTABLE_HOME_DIR" && ! -d "$RIM_PORTABLE_HOME_DIR" ]] && \
                try_mkdir "$RIM_PORTABLE_HOME_DIR"
            if [ -d "$RIM_PORTABLE_HOME_DIR" ]
                then
                    export HOME="$RIM_PORTABLE_HOME_DIR"
                    SET_HOME_DIR=1
                    export RIM_PORTABLE_HOME=1
            elif [[ "$RIM_PORTABLE_HOME" == 1 || -d "$PORTABLEHOMEDIR/$RUNSRCNAME" ]]
                then
                    export HOME="$PORTABLEHOMEDIR/$RUNSRCNAME"
                    SET_HOME_DIR=1
                    export RIM_PORTABLE_HOME=1
            elif [ -n "$RUNIMAGE" ] && [[ "$RIM_PORTABLE_HOME" == 1 || -d "$PORTABLEHOMEDIR/$RUNIMAGENAME" ]]
                then
                    export HOME="$PORTABLEHOMEDIR/$RUNIMAGENAME"
                    SET_HOME_DIR=1
                    export RIM_PORTABLE_HOME=1
            elif [[ "$RIM_PORTABLE_HOME" == 1 || -d "$PORTABLEHOMEDIR/Run" ]]
                then
                    export HOME="$PORTABLEHOMEDIR/Run"
                    SET_HOME_DIR=1
                    export RIM_PORTABLE_HOME=1
            fi
    fi
fi
if [[ "$RIM_PORTABLE_HOME" == 1 && -n "$SYS_HOME" ]]
    then export SYS_HOME
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

unset SET_CONF_DIR
if [ "$RIM_PORTABLE_CONFIG" != 0 ]
    then
        if [[ "$RIM_PORTABLE_CONFIG" == 1 || -d "$RUNIMAGEDIR/$RUNSRCNAME.config" ]]
            then
                export XDG_CONFIG_HOME="$RUNIMAGEDIR/$RUNSRCNAME.config"
                SET_CONF_DIR=1
        elif [ -n "$RUNIMAGE" ] && [[ "$RIM_PORTABLE_CONFIG" == 1 || -d "$RUNIMAGE.config" ]]
            then
                export XDG_CONFIG_HOME="$RUNIMAGE.config"
                SET_CONF_DIR=1
        elif [[ "$RIM_PORTABLE_CONFIG" == 1 || -d "$RUNIMAGEDIR/Run.config" ]]
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
    "$RIM_TMP_HOME" == 1 || "$RIM_TMP_HOME_DL" == 1 || \
    "$RIM_SANDBOX_HOME" == 1 || "$RIM_SANDBOX_HOME_DL" ]]
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

[[ -n "$RIM_SNET_CIDR" || -n "$RIM_SNET_MTU" ||\
   -n "$RIM_SNET_TAPNAME" || -n "$RIM_SNET_MAC" ||\
   "$RIM_SNET_SHARE_HOST" == 1 || -n "$RIM_SNET_TAPIP" ||\
   "$RIM_SNET_DROP_CIDRS" == 1 || -n "$RIM_SNET_PORTFW" ]] && \
    RIM_SANDBOX_NET=1

if [ "$SUID_BWRAP" == 1 ]
    then
        [ "$RIM_SANDBOX_NET" == 1 ] && \
            disable_sandbox_net
        RIM_NO_BWRAP_OVERLAY=1
fi

if [[ "$RIM_SANDBOX_NET" == 1 && ! -e '/dev/net/tun' ]]
    then
        tun_err_text="RIM_SANDBOX_NET enabled, but /dev/net/tun not found!"
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

if [[ "$RIM_SANDBOX_NET" == 1 || "$RIM_NO_NET" == 1 ]] && [ "$RIM_UNSHARE_DBUS" != 1 ] && \
    [[ "$DBUS_SESSION_BUS_ADDRESS" =~ "unix:abstract" ]]
    then
        DBUSP_SOCKET="$RUNPIDDIR/rdbus"
        info_msg "Launching socat dbus proxy..."
        socat UNIX-LISTEN:"$DBUSP_SOCKET",reuseaddr,fork \
            ABSTRACT-CONNECT:"$(echo "$DBUS_SESSION_BUS_ADDRESS"|\
                                sed 's|unix:abstract=||g;s|,guid=.*$||g')" &
        DBUSP_PID="$!"
        sleep 0.05
        if is_pid "$DBUSP_PID" && [ -S "$DBUSP_SOCKET" ]
            then
                SETENV_ARGS+=("--setenv" "DBUS_SESSION_BUS_ADDRESS" "unix:path=$DBUSP_SOCKET")
            else
                error_msg "Failed to start socat dbus proxy!"
        fi
fi

if [[ "$RIM_NO_NET" == 1 || "$RIM_SANDBOX_NET" == 1 ]]
    then
        NETWORK_BIND=("--unshare-net")
        [ "$RIM_NO_NET" == 1 ] && \
            warn_msg "Network is disabled!"
        export RUNPORTFW="$RUNPIDDIR/portfw"
    else
        NETWORK_BIND=("--share-net")
        if [ "$RIM_UNSHARE_HOSTS" == 1 ]
            then warn_msg "Host '/etc/hosts' is unshared!"
            else NETWORK_BIND+=("--ro-bind-try" "/etc/hosts" "/etc/hosts")
        fi
        if [ "$RIM_UNSHARE_RESOLVCONF" == 1 ]
            then warn_msg "Host '/etc/resolv.conf' is unshared!"
            else NETWORK_BIND+=("--ro-bind-try" "/etc/resolv.conf" "/etc/resolv.conf")
        fi
fi
if [ ! -n "$RIM_HOSTS_FILE" ]
    then
        if [ -f "$RUNIMAGEDIR/hosts" ]
            then RIM_HOSTS_FILE="$RUNIMAGEDIR/hosts"
        elif [ -f "$RUNDIR/hosts" ]
            then RIM_HOSTS_FILE="$RUNDIR/hosts"
        fi
fi
if [[ -f "$RIM_HOSTS_FILE" && "$RIM_HOSTS_FILE" != 0 ]]
    then
        info_msg "Bind: '$RIM_HOSTS_FILE' -> '/etc/hosts'"
        NETWORK_BIND+=("--bind-try" "$RIM_HOSTS_FILE" "/etc/hosts")
fi
if [ ! -n "$RIM_RESOLVCONF_FILE" ]
    then
        if [ -f "$RUNIMAGEDIR/resolv.conf" ]
            then RIM_RESOLVCONF_FILE="$RUNIMAGEDIR/resolv.conf"
        elif [ -f "$RUNDIR/resolv.conf" ]
            then RIM_RESOLVCONF_FILE="$RUNDIR/resolv.conf"
        fi
fi
if [[ -f "$RIM_RESOLVCONF_FILE" && "$RIM_RESOLVCONF_FILE" != 0 ]]
    then
        info_msg "Bind: '$RIM_RESOLVCONF_FILE' -> '/etc/resolv.conf'"
        NETWORK_BIND+=("--bind-try" "$RIM_RESOLVCONF_FILE" "/etc/resolv.conf")
fi

XORG_CONF_BIND=()
if [ "$RIM_XORG_CONF" != 0 ]
    then
        if [ ! -n "$RIM_XORG_CONF" ]
            then
                if [ -f "$RUNIMAGEDIR/xorg.conf" ]
                    then RIM_RESOLVCONF_FILE="$RUNIMAGEDIR/xorg.conf"
                elif [ -f "$RUNDIR/xorg.conf" ]
                    then RIM_RESOLVCONF_FILE="$RUNDIR/xorg.conf"
                fi
        fi
        if [[ -f "$RIM_XORG_CONF" && "$(basename "$RIM_XORG_CONF")" == "xorg.conf" ]]
            then
                info_msg "Found xorg.conf in: '$RIM_XORG_CONF'"
                XORG_CONF_BIND+=("--ro-bind-try" \
                                "$RIM_XORG_CONF" "/etc/X11/xorg.conf")
        elif [ -f "/etc/X11/xorg.conf" ]
            then
                info_msg "Found xorg.conf in: '/etc/X11/xorg.conf'"
                XORG_CONF_BIND+=("--ro-bind-try" \
                                "/etc/X11/xorg.conf" "/etc/X11/xorg.conf")
        fi
    else
        warn_msg "Bind xorg.conf is disabled!"
fi

[ "$RIM_HOST_XDG_OPEN" == 1 ] && \
    RIM_HOST_TOOLS+=',xdg-open'

if [[ -n "$RIM_HOST_TOOLS" && "$RIM_HOST_TOOLS" != 0 ]]
    then
        RIM_ENABLE_HOSTEXEC=1
        HOST_TOOLS_BIND=(--dir /var/host/bin)
        [ ! -w "$RUNROOTFS/var/host/bin" ] && \
            HOST_TOOLS_BIND=(--tmpfs /var/host/bin)
        IFS=',' read -r -a tools <<<"$RIM_HOST_TOOLS"
        for tool in "${tools[@]}"
            do
                if [ -n "$(which_sys_exe "$tool")" ]
                    then
                        info_msg "Share host tool: $tool"
                        HOST_TOOLS_BIND+=("--bind-try" "$RUNUTILS/hostexec" "/var/host/bin/$tool")
                fi
        done
        add_bin_pth '/var/host/bin'
    else unset HOST_TOOLS_BIND
fi

if [ "$RIM_ENABLE_HOSTEXEC" == 1 ]
    then
        HEXECFLDIR="$RUNPIDDIR/hexec"
        try_mkdir "$HEXECFLDIR"
        export RIM_HEXEC_SOCK="$HEXECFLDIR/s"
        warn_msg "HOSTEXEC option is enabled!"
        ([ -n "$SYS_HOME" ] && \
            export HOME="$SYS_HOME"
        SSRV_SOCK="unix:$RIM_HEXEC_SOCK" \
        SSRV_CPIDS_DIR="$HEXECFLDIR/cpids" \
        SSRV_PID_FILE="$HEXECFLDIR/ssrv.pid" \
        PATH="$SYS_PATH:$RUNSTATIC:$RUNUTILS" \
        SSRV_UENV="$(tr ' ' ','<<<"${!RIM_@}")" \
        exec "$SSRV_ELF" -srv -env all &>/dev/null) &
fi

MACHINEID_BIND=()
if [[ -f "/var/lib/dbus/machine-id" && -f "/etc/machine-id" ]]
    then MACHINEID_BIND+=("--ro-bind-try" "/etc/machine-id" "/etc/machine-id" \
                          "--ro-bind-try" "/var/lib/dbus/machine-id" "/var/lib/dbus/machine-id")
elif [[ -f "/var/lib/dbus/machine-id" && ! -f "/etc/machine-id" ]]
    then MACHINEID_BIND+=("--ro-bind-try" "/var/lib/dbus/machine-id" "/etc/machine-id" \
                          "--ro-bind-try" "/var/lib/dbus/machine-id" "/var/lib/dbus/machine-id")
elif [[ -f "/etc/machine-id" && ! -f "/var/lib/dbus/machine-id" ]]
    then MACHINEID_BIND+=("--ro-bind-try" "/etc/machine-id" "/etc/machine-id" \
                          "--ro-bind-try" "/etc/machine-id" "/var/lib/dbus/machine-id")
fi

VAR_BIND=(
    "--bind-try" "/var/mnt" "/var/mnt"
    "--bind-try" "/var/home" "/var/home"
    "--bind-try" "/var/roothome" "/var/roothome"
)
[ -e '/var/log/wtmp' ] && \
VAR_BIND+=("--bind-try" "/var/log/wtmp" "/var/log/wtmp")
[ -e '/var/log/lastlog' ] && \
VAR_BIND+=("--bind-try" "/var/log/lastlog" "/var/log/lastlog")

if [ ! -w "$RUNROOTFS" ]
    then
        VAR_BIND+=(
            "--tmpfs" "/var/log"
            "--tmpfs" "/var/tmp"
        )
fi

NSS_BIND=()
if [ "$RIM_UNSHARE_NSS" == 1 ]
    then warn_msg "NSS is unshared!"
    else NSS_BIND+=('--ro-bind-try' '/etc/nsswitch.conf' '/etc/nsswitch.conf')
fi

if [ "$RIM_UNSHARE_HOSTNAME" == 1 ]
    then
        warn_msg "Hostname is unshared!"
        HOSTNAME_BIND=('--unshare-uts' '--hostname' 'runimage')
    else
        HOSTNAME_BIND=('--ro-bind-try' '/etc/hostname' '/etc/hostname')
fi

USERS_BIND=()
if [ "$RIM_UNSHARE_USERS" == 1 ]
    then
        warn_msg "Users are unshared!"
        USERS_BIND+=("--unshare-user-try")
        if ! grep -wo "^$RUNUSER:x:$EUID:0" "$RUNROOTFS/etc/passwd" &>/dev/null || \
           ! grep -wo "^$RUNGROUP:x:$EGID:" "$RUNROOTFS/etc/group" &>/dev/null
            then
                if [ -w "$RUNROOTFS" ]
                    then
                        add_unshared_user "$RUNROOTFS/etc/passwd"
                        add_unshared_group "$RUNROOTFS/etc/group"
                    else
                        UNGROUPFL="$RUNPIDDIR/group"
                        UNPASSWDFL="$RUNPIDDIR/passwd"
                        cp -f "$RUNROOTFS/etc/group" "$UNGROUPFL" 2>/dev/null
                        cp -f "$RUNROOTFS/etc/passwd" "$UNPASSWDFL" 2>/dev/null
                        add_unshared_user "$UNPASSWDFL"
                        add_unshared_group "$UNGROUPFL"
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

FONTS_BIND=()
if [[ "$RIM_SHARE_FONTS" == 1 && -d '/usr/share/fonts' ]]
    then
        info_msg "Host /usr/share/fonts is shared!"
        FONTS_BIND+=('--ro-bind-try' '/usr/share/fonts' '/usr/share/fonts')
fi

THEMES_BIND=()
if [[ "$RIM_SHARE_THEMES" == 1 && -d '/usr/share/themes' ]]
    then
        info_msg "Host /usr/share/themes is shared!"
        THEMES_BIND+=('--ro-bind-try' '/usr/share/themes' '/usr/share/themes')
fi

BOOT_BIND=()
if [[ "$RIM_SHARE_BOOT" == 1 && -d '/boot' ]]
    then
        info_msg "Host /boot is shared!"
        BOOT_BIND+=('--ro-bind-try' '/boot' '/boot')
fi

PKGCACHE_BIND=()
if [ "$RIM_SHARE_PKGCACHE" == 1 ]
    then
        unset pkgcache
        if [ -d '/var/cache/pacman' ]
            then pkgcache='/var/cache/pacman'
        elif [ -d '/var/cache/apk' ]
            then pkgcache='/var/cache/apk'
        elif [ -d '/var/cache/xbps' ]
            then pkgcache='/var/cache/xbps'
        elif [ -d '/var/cache/apt' ]
            then pkgcache='/var/cache/apt'
        fi
        if [ -n "$pkgcache" ]
            then
                info_msg "Host $pkgcache is shared!"
                PKGCACHE_BIND+=("--ro-bind-try" "$pkgcache" "$pkgcache")
        fi
fi

MODULES_BIND=()
if [ "$RIM_UNSHARE_MODULES" != 1 ]
    then
        unset libmodules
        if [ -d "/lib/modules" ]
            then libmodules="/lib/modules"
        elif [ -d "/usr/lib/modules" ]
            then libmodules="/usr/lib/modules"
        fi
        [ -n "$libmodules" ] && \
        MODULES_BIND+=("--ro-bind-try" "$libmodules" "/usr/lib/modules")
    else
        warn_msg "Kernel modules are unshared!"
fi

[ "$RIM_BIND_PWD" == 1 ] &&
    RIM_BIND+=",$PWD:$PWD"

if [ -n "$RIM_BIND" ]
    then
        BWRAP_BIND=()
        IFS=',' read -r -a pairs <<< "$RIM_BIND"
        for pair in "${pairs[@]}"
            do
                IFS=':' read -r src dst<<<"$pair"
                if [ -e "$src" ]
                    then
                        info_msg "Bind: '$src' -> '$dst'"
                        BWRAP_BIND+=("--bind-try" "$src" "$dst")
                fi
        done
    else unset BWRAP_BIND
fi

if [ "$RIM_DESKTOP_INTEGRATION" == 1 ] && \
     [[ "$RIM_TMP_HOME" == 1 || "$RIM_TMP_HOME_DL" == 1 ||\
    "$RIM_SANDBOX_HOME" == 1 || "$RIM_SANDBOX_HOME_DL" == 1 ||\
    "$RIM_UNSHARE_HOME" == 1 || "$RIM_UNSHARE_HOME_DL" == 1 ]]
    then
        export RUNDINTEGDIR="$RUNPIDDIR/dinteg"
        try_mkdir "$RUNDINTEGDIR"
        dinteg() {
            unset -f dinteg
            [ -n "$SYS_HOME" ] && \
                export HOME="$SYS_HOME"
            ACTINTEGFL="$RUNDINTEGDIR/act"
            ADDINTEGFL="$RUNDINTEGDIR/add"
            RMINTEGFL="$RUNDINTEGDIR/rm"
            LSINTEGFL="$RUNDINTEGDIR/ls"
            mkfifo "$ACTINTEGFL"
            mkfifo "$ADDINTEGFL"
            mkfifo "$RMINTEGFL"
            mkfifo "$LSINTEGFL"
            unset RUNDINTEGDIR
            while [[ -n "$RUNPID" && -d "/proc/$RUNPID" ]]
                do
                    case "$(cat "$ACTINTEGFL" 2>/dev/null)" in
                        a)
                            newdinteg="$(cat "$ADDINTEGFL" 2>/dev/null)"
                            if [ -n "$newdinteg" ]
                                then "$RUNSTATIC/bash" "$RUNUTILS/rim-dinteg" --add hook<<<"$newdinteg"
                            fi
                        ;;
                        r)
                            rmdinteg="$(cat "$RMINTEGFL" 2>/dev/null)"
                            if [ -n "$rmdinteg" ]
                                then "$RUNSTATIC/bash" "$RUNUTILS/rim-dinteg" --remove hook<<<"$rmdinteg"
                            fi
                        ;;
                        l) "$RUNSTATIC/bash" "$RUNUTILS/rim-dinteg" --list added>"$LSINTEGFL" ;;
                    esac
            done
        }
        export -f dinteg
        "$RUNSTATIC/bash" -c dinteg &
        unset -f dinteg
fi

export -p|grep '^declare -x RIM_.*='|sed 's|^declare -x ||g' > "$RIMENVFL"

##############################################################################

case "$ARG1" in
    rim-encfs     ) encrypt_rootfs "${ARGS[@]}" ;;
    rim-decfs     ) decrypt_rootfs "${ARGS[@]}" ;;
    rim-enc-passwd) passwd_cryptfs "${ARGS[@]}" ;;
    rim-pkgls     ) pkg_list ;;
    rim-kill      ) force_kill "${ARGS[@]}" ;;
    rim-help      ) print_help ;;
    rim-binlist   ) bin_list ;;
    rim-version   ) print_version ;;
    rim-ofsls     ) overlayfs_list ;;
    rim-update    ) run_update "${ARGS[@]}" ;;
    rim-ofsrm     ) overlayfs_rm "${ARGS[@]}" ;;
    rim-desktop   ) bwrun rim-desktop "${ARGS[@]}" ;;
    rim-shell     ) bwrun "${RIM_SHELL[@]}" "${ARGS[@]}" ;;
    rim-psmon     ) bwrun rim-psmon "${ARGS[@]}" ;;
    rim-build     ) run_build "${ARGS[@]}" ;;
    *)
        if [ -n "$RIM_AUTORUN" ]
            then
                [ "$ARG1" != "$(basename "$RUNSRC")" ] && [[ "$ARG1" == "$AUTORUN0ARG" ||\
                  "$ARG1" == "$(basename "${RIM_CONFIG%.rcfg}")" ||\
                  "$ARG1" == "$(basename "${RUNIMAGE_INTERNAL_CONFIG%.rcfg}")" ]] && \
                    ARGS=("${ARGS[@]:1}")
                if [ "${#RIM_AUTORUN[@]}" == 1 ]
                    then bwrun $RIM_AUTORUN "${ARGS[@]}"
                    else bwrun "${RIM_AUTORUN[@]}" "${ARGS[@]}"
                fi
            else
                if [[ ! -n "$ARG1" && ! -n "$RIM_EXEC_ARGS" ]]
                    then bwrun "${RIM_SHELL[@]}"
                    else bwrun "${ARGS[@]}"
                fi
        fi
    ;;
esac

exit $?

##############################################################################
