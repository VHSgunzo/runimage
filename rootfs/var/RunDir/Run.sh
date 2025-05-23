#!/usr/bin/env bash
shopt -s extglob

DEVELOPERS="VHSgunzo"
export RUNIMAGE_VERSION='0.41.1'

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
export RUNDIRFL="$RUNPIDDIR/rundir"
export SSRV_CPIDS_DIR="$RUNPIDDIR/cpids"
export SSRV_PID_FILE="$RUNPIDDIR/ssrv.pid"
export SSRV_NOSEP_CPIDS=1
export SSRV_ENV='SSRV_PID'

unset SESSION_MANAGER POSIXLY_CORRECT LD_PRELOAD ENV FORCE_KILL_PPID \
    NVIDIA_DRIVER_BIND BIND_LDSO_CACHE FUSE_PIDS REBUILD_RUNIMAGE

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
        export PATH="$SYS_PATH:/bin:/sbin:/usr/bin:/usr/sbin:$RUNSTATIC:$RUNUTILS"||\
        export PATH="$RUNSTATIC:$RUNUTILS:$SYS_PATH:/bin:/sbin:/usr/bin:/usr/sbin"
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
export REALRUNSRC="$(realpath "$RUNSRC")"

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
    echo -e "${RED}[ ERROR ][$(date +"%Y.%m.%d %T")]: $@ $RESETCOLOR" 1>&2
    if [ "$NOT_TERM" == 1 ]
        then notify-send -a 'RunImage Error' "$(echo -e "$@"|nocolor)" 2>/dev/null &
    fi
}

info_msg() {
    if [ "$RIM_QUIET_MODE" != 1 ]
        then echo -e "${GREEN}[ INFO ][$(date +"%Y.%m.%d %T")]: $@ $RESETCOLOR" 1>&2
            if [[ "$NOT_TERM" == 1 && "$RIM_NOTIFY" == 1 ]]
                then notify-send -a 'RunImage Info' "$(echo -e "$@"|nocolor)" 2>/dev/null &
            fi
    fi
}

warn_msg() {
    if [[ "$RIM_QUIET_MODE" != 1 && "$RIM_NO_WARN" != 1 ]]
        then echo -e "${YELLOW}[ WARNING ][$(date +"%Y.%m.%d %T")]: $@ $RESETCOLOR" 1>&2
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
        DL_REP_TEXT="Failed to download: $FILENAME from $(echo "$URL"|gawk -F/ '{print$3"/"$4}') \nWould you like to repeat it?"
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
                                return $ret
                            }
                            if [ "$NO_ARIA2C" != 1 ] && \
                                is_exe_exist aria2c
                                then
                                    aria2c --no-conf -R -x 13 -s 13 --allow-overwrite --summary-interval=1 -o \
                                        "$FILENAME" -d "$FILEDIR" "$URL"|grep --line-buffered 'ETA'|\
                                        sed -u 's|(.*)| &|g;s|(||g;s|)||g;s|\[||g;s|\]||g'|\
                                        gawk '{print$3"\n#Downloading at "$3,$2,$5,$6;system("")}'|\
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
                    error_msg "$FILENAME not found in $(echo "$URL"|gawk -F/ '{print$3"/"$4}')"
                    return 1
            fi
        else
            error_msg "Specify download URL!"
            return 1
    fi
}

get_nvidia_driver_image() {
    (local ret=1
    unset rmnvsrc
    if [[ -n "$1" || -n "$nvidia_version" ]]
        then
            [ ! -n "$nvidia_version" ] && \
                nvidia_version="$1"
            [ ! -n "$NVDRVARCH" ] && \
                NVDRVARCH="$(uname -m)"
            [[ -d "$2" && ! -n "$NVIDIA_DRIVERS_DIR" ]] && \
                export NVIDIA_DRIVERS_DIR="$2"
            [[ ! -d "$2" && ! -n "$NVIDIA_DRIVERS_DIR" ]] && \
                export NVIDIA_DRIVERS_DIR="."
            [ ! -n "$nvidia_driver_image" ] && \
                nvidia_driver_image="$nvidia_version.nv.drv"
            try_mkdir "$NVIDIA_DRIVERS_DIR"
            NVBINS=(
                'mkprecompiled' 'nvidia-cuda-mps-control' 'nvidia-cuda-mps-server'
                'nvidia-debugdump' 'nvidia-installer' 'nvidia-modprobe'
                'nvidia-ngx-updater' 'tls_test' 'nvidia-persistenced' 'nvidia-powerd'
                'nvidia-settings' 'nvidia-smi' 'nvidia-xconfig' 'nvidia-pcc'
                'nvidia-cuda-mps-srv' 'nvidia-bug-report.sh' 'nvidia-sleep.sh'
            )
            if [[ "$RIM_SYS_NVLIBS" == 1 || "$NVDRVARCH" != 'x86_64' ]]
                then
                    info_msg "Find Nvidia ${nvidia_version} local libs, please wait..."
                    cp_nvfiles() (
                        local sys_pth
                        local dir="$1"
                        shift
                        mkdir -p "$dir" && \
                        cd "$dir"||return 1
                        for file in "$@"
                            do
                                case "$dir" in
                                    64|32) sys_pth="$(realpath "$file" 2>/dev/null)" ;;
                                    bin) sys_pth="$(command -v "$file" 2>/dev/null)" ;;
                                    wine) sys_pth="$(find /usr -type f -name "$file" 2>/dev/null|head -1)" ;;
                                    .) sys_pth="$(ls "$file" 2>/dev/null|head -1)" ;;
                                    *) sys_pth="$(find /etc/ /usr/share -name "*${file}" -type f 2>/dev/null|head -1)" ;;
                                esac
                                if [ -n "$sys_pth" ]
                                    then
                                        local file="$(basename "$sys_pth")"
                                        if [[ ! -e "$file" && -e "$sys_pth" ]]
                                            then cp -f "$sys_pth" "$file"
                                        fi
                                fi
                        done
                    )
                    [ "$NVDRVARCH" != 'x86_64' ] && \
                        RIM_NO_32BIT_NVLIBS_CHECK=1
                    NVTRASH_LIBS=('libnvidia-container*')
                    NVCONFS=('nvidia-dbus.conf' '-nvidia-drm-outputclass.conf' 'nvidia.icd' '-nvidia.conf')
                    NVJSONS=(
                        '_nvidia.json' '_nvidia_wayland.json' '_nvidia_gbm.json'
                        'nvidia_icd.json' 'nvidia_layers.json' '_nvidia_xcb.json'
                        '_nvidia_xlib.json' 'nvidia_icd_vksc.json'
                    )
                    PROFS=(
                        "nvidia-application-profiles-${nvidia_version}-key-documentation"
                        "nvidia-application-profiles-${nvidia_version}-rc"
                        'nvoptix.bin'
                    )
                    NVWINELS=('_nvngx.dll'  'nvngx.dll' 'nvngx_dlssg.dll')
                    LICENSES=(
                        '/usr/share/licenses/nvidia-utils/LICENSE'
                        /usr/share/doc/nvidia-driver-*/LICENSE
                    )
                    NVLIBS="$(if is_exe_exist ldconfig
                        then ldconfig -p
                    elif is_exe_exist strings && [ -f '/etc/ld.so.cache' ]
                        then strings /etc/ld.so.cache
                    fi|grep -E 'nvidia|nvoptix|libcuda|libnvcuvid'|sed 's|.*=> ||g'|sort -u)"
                    for lib in "${NVTRASH_LIBS[@]}"
                        do NVLIBS="$(grep -v "$lib"<<<"$NVLIBS")"
                    done
                    NVLIBS64=($(grep -E "/lib/|/${NVDRVARCH}-linux-gnu/"<<<"$NVLIBS"))
                    for pth in lib "${NVDRVARCH}-linux-gnu"
                        do
                            libs=(
                                "/usr/$pth/vdpau/libvdpau_nvidia.so"
                                "/usr/$pth/xorg/modules/drivers/nvidia_drv.so"
                                "/usr/$pth/nvidia/xorg/libglxserver_nvidia.so"
                            )
                            for lib in "${libs[@]}"
                                do [ -e "$lib" ] && NVLIBS64+=("$lib")
                            done
                    done
                    if [ ! -n "$NVLIBS64" ]
                        then
                            error_msg "Nvidia libraries are not found in your system!"
                            if [[ "$NVLIBS_DLFAILED" == 1 || "$NVDRVARCH" != 'x86_64' ]]
                                then return 1
                                else
                                    RIM_SYS_NVLIBS=0 get_nvidia_driver_image
                                    return $?
                            fi
                    fi
                    NVLIBS32=($(grep -E '/lib32/|/i386-linux-gnu/'<<<"$NVLIBS"))
                    for pth in lib32 i386-linux-gnu
                        do
                            nvvdpau="/usr/$pth/vdpau/libvdpau_nvidia.so"
                            [ -e "$nvvdpau" ] && NVLIBS32+=("$nvvdpau")
                    done
                    if [[ ! -n "$NVLIBS32" && "$RIM_NO_32BIT_NVLIBS_CHECK" != 1 ]]
                        then
                            error_msg "Nvidia 32-bit libraries are not found in your system!"
                            info_msg "Use ${YELLOW}RIM_NO_32BIT_NVLIBS_CHECK=1 ${GREEN}if they are not required."
                            if [ "$NVLIBS_DLFAILED" == 1 ]
                                then return 1
                                else
                                    RIM_SYS_NVLIBS=0 get_nvidia_driver_image
                                    return $?
                            fi
                    fi
                    info_msg "Creating a driver directory structure..."
                    (cd "$NVIDIA_DRIVERS_DIR" && \
                    mkdir -p "$nvidia_version" && \
                    cd "$nvidia_version"
                    cp_nvfiles 32 "${NVLIBS32[@]}"
                    cp_nvfiles 64 "${NVLIBS64[@]}"
                    cp_nvfiles bin "${NVBINS[@]}"
                    cp_nvfiles conf "${NVCONFS[@]}"
                    cp_nvfiles json "${NVJSONS[@]}"
                    if [[ ! -e 'profiles' && -d '/usr/share/nvidia' ]]
                        then cp -rf '/usr/share/nvidia' 'profiles'
                        else cp_nvfiles profiles "${NVJSONS[@]}"
                    fi
                    if [[ ! -e 'wine' && -d '/usr/lib/nvidia/wine' ]]
                        then cp -rf '/usr/lib/nvidia/wine' 'wine'
                        else cp_nvfiles wine "${NVWINELS[@]}"
                    fi
                    cp_nvfiles . "${LICENSES[@]}")
                else
                    info_msg "Downloading Nvidia ${nvidia_version} driver, please wait..."
                    nvidia_driver_run="NVIDIA-Linux-x86_64-${nvidia_version}.run"
                    driver_url_list=(
                        "https://storage.yandexcloud.net/runimage/nvidia-drivers/$nvidia_driver_image"
                        "https://huggingface.co/runimage/nvidia-drivers/resolve/main/releases/$nvidia_driver_image"
                        "https://github.com/VHSgunzo/runimage-nvidia-drivers/releases/download/v${nvidia_version}/$nvidia_driver_image"
                        "https://download.nvidia.com/XFree86/Linux-x86_64/${nvidia_version}/$nvidia_driver_run"
                        "https://us.download.nvidia.com/tesla/${nvidia_version}/$nvidia_driver_run"
                        "https://developer.nvidia.com/downloads/vulkan-beta-${nvidia_version//.}-linux"
                        "https://developer.nvidia.com/vulkan-beta-${nvidia_version//.}-linux"
                        "https://developer.nvidia.com/linux-${nvidia_version//.}"
                    )
                    if try_dl "${driver_url_list[0]}" "$NVIDIA_DRIVERS_DIR"||\
                        try_dl "${driver_url_list[1]}" "$NVIDIA_DRIVERS_DIR"||\
                        try_dl "${driver_url_list[2]}" "$NVIDIA_DRIVERS_DIR"
                        then return 0
                    elif try_dl "${driver_url_list[3]}" "$NVIDIA_DRIVERS_DIR"||\
                        try_dl "${driver_url_list[4]}" "$NVIDIA_DRIVERS_DIR"||\
                        try_dl "${driver_url_list[5]}" "$NVIDIA_DRIVERS_DIR" "$nvidia_driver_run"||\
                        try_dl "${driver_url_list[6]}" "$NVIDIA_DRIVERS_DIR" "$nvidia_driver_run"||\
                        try_dl "${driver_url_list[7]}" "$NVIDIA_DRIVERS_DIR" "$nvidia_driver_run"
                        then
                            trash_libs="libEGL.so* libGLdispatch.so* *.swidtag *.la \
                                libGLESv!(*nvidia).so* libGL.so* libGLX.so* libOpenCL.so* libOpenGL.so*"
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
                                [ -n "$(ls *.dll 2>/dev/null)" ] && try_mkdir wine && mv *.dll wine
                                try_mkdir json && mv *.json json
                                try_mkdir conf && mv *.conf *.icd conf
                                for lib in $trash_libs ; do rm -f $lib 32/$lib ; done
                                try_mkdir bin && mv *.sh bin
                                for binary in "${NVBINS[@]}" ; do [ -f "$binary" ] && mv $binary bin ; done
                                try_mkdir 64 && mv *.so* 64
                                [ -d "tls" ] && mv tls/* 64 && rm -rf tls
                                [ -d "32/tls" ] && mv 32/tls/* 32 && rm -rf 32/tls)
                        else
                            error_msg "Failed to download nvidia driver!"
                            if [ "$NVLIBS_SYSFAILED" != 1 ]
                                then
                                    RIM_SYS_NVLIBS=1 NVLIBS_DLFAILED=1 get_nvidia_driver_image
                                    return $?
                            fi
                            return 1
                    fi
            fi
            if [ -e "$NVIDIA_DRIVERS_DIR/$nvidia_version/64/libGLX_nvidia.so.$nvidia_version" ]
                then
                    info_msg "Creating a SquashFS driver image..."
                    info_msg "$NVIDIA_DRIVERS_DIR/$nvidia_driver_image"
                    echo -en "$BLUE"
                    if "$MKSQFS" "$NVIDIA_DRIVERS_DIR/$nvidia_version" "$NVIDIA_DRIVERS_DIR/$nvidia_driver_image" \
                        -root-owned -no-xattrs -noappend -b 1M -comp zstd -Xcompression-level 1 -quiet
                        then ret=0
                        else error_msg "Failed to create Nvidia driver image!"
                    fi
                    echo -en "$RESETCOLOR"
                else
                    error_msg "libGLX_nvidia.so.$nvidia_version not found in the source directory of the driver!"
                    rmnvsrc=1
            fi
            if [ -d "$NVIDIA_DRIVERS_DIR/$nvidia_version" ] && [[ "$ret" == 0 || "$rmnvsrc" == 1 ]]
                then
                    info_msg "Deleting the source directory of the driver..."
                    rm -rf "$NVIDIA_DRIVERS_DIR/$nvidia_version"
            fi
            if [[ "$RIM_SYS_NVLIBS" == 1 && "$rmnvsrc" == 1 ]]
                then
                    RIM_SYS_NVLIBS=0 NVLIBS_SYSFAILED=1 get_nvidia_driver_image
                    return $?
            fi
        else
            error_msg "You must specify the nvidia driver version!"
    fi
    return $ret)
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
            "$SQFUSE" -f -o ro,nodev,uid=$EUID,gid=$EGID \
                "$1" "$NVDRVMNT" &>/dev/null &
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
    unset NVIDIA_DRIVER_BIND NVLIBS_DLFAILED NVLIBS_SYSFAILED
    is_inside_ver_eq() { [ "$(cat "$RUNROOTFS/etc/ld.so.version" 2>/dev/null)" == "$RUNROOTFS_VERSION-$nvidia_version" ] ; }
    print_nv_drv_dir() { info_msg "Found nvidia driver directory: $(basename "$nvidia_driver_dir")" ; }
    update_ld_cache() {
        if [[ "$(cat "$RUNCACHEDIR/ld.so.version" 2>/dev/null)" != "$RUNROOTFS_VERSION-$nvidia_version" ]]||\
           ([ -f "$RUNROOTFS/etc/ld.so.version" ] && ! is_inside_ver_eq)||\
           ([ -w "$RUNROOTFS" ] && ! is_inside_ver_eq)
            then
                info_msg "Updating the nvidia library cache..."
                if (RIM_SANDBOX_NET=0 RIM_NO_NET=0 RIM_WAIT_RPIDS_EXIT=0 \
                    RIM_NO_BWRAP_OVERLAY=1 SSRV_SOCK="unix:$RUNPIDDIR/ldupd" \
                    bwrun /usr/bin/ldconfig -C "$RUNPIDDIR/ld.so.cache" 2>/dev/null </dev/null)
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
        fi
    }
    NVDRVARCH="$(uname -m)"
    if [ -e '/sys/module/nvidia/version' ]||\
        grep -owm1 nvidia /proc/modules &>/dev/null
        then
            unset NVDRVMNT nvidia_driver_dir
            [[ -n "$RIM_NVIDIA_DRIVERS_DIR" && ! -d "$RIM_NVIDIA_DRIVERS_DIR" ]] && \
                try_mkdir "$RIM_NVIDIA_DRIVERS_DIR"
            [ -d "$RIM_NVIDIA_DRIVERS_DIR" ] && \
            NVIDIA_DRIVERS_DIR="$RIM_NVIDIA_DRIVERS_DIR"||\
            NVIDIA_DRIVERS_DIR="$RUNIMAGEDIR/nvidia-drivers"
            export NVIDIA_DRIVERS_DIR
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
                if [ -d "/usr/lib/${NVDRVARCH}-linux-gnu" ]
                    then
                        nvidia_version="$(basename /usr/lib/${NVDRVARCH}-linux-gnu/libGLX_nvidia.so.*.*|tail -c +18)"
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
                                    if [ ! -f "$NVIDIA_DRIVERS_DIR/$nvidia_version/64/libGLX_nvidia.so.$nvidia_version" ] && \
                                        [ ! -f "$RUNIMAGEDIR/$nvidia_driver_image" ] && \
                                        [ ! -f "$NVIDIA_DRIVERS_DIR/$nvidia_driver_image" ] && \
                                        [ ! -f "$NVDRVMNT/64/libGLX_nvidia.so.$nvidia_version" ] && \
                                        [ ! -f "$RUNDIR/nvidia-drivers/$nvidia_version/64/libGLX_nvidia.so.$nvidia_version" ] && \
                                        [ ! -f "$RUNDIR/nvidia-drivers/$nvidia_driver_image" ]
                                        then
                                            if RIM_NOTIFY=1 RIM_QUIET_MODE=0 get_nvidia_driver_image
                                                then
                                                    mount_nvidia_driver_image "$NVIDIA_DRIVERS_DIR/$nvidia_driver_image"
                                                else
                                                    nvidia_driver_dir="$NVIDIA_DRIVERS_DIR/$nvidia_version"
                                            fi
                                        else
                                            if [ -f "$NVDRVMNT/64/libGLX_nvidia.so.$nvidia_version" ]
                                                then
                                                    nvidia_driver_dir="$NVDRVMNT"
                                                    print_nv_drv_dir
                                            elif [ -f "$NVIDIA_DRIVERS_DIR/$nvidia_version/64/libGLX_nvidia.so.$nvidia_version" ]
                                                then
                                                    nvidia_driver_dir="$NVIDIA_DRIVERS_DIR/$nvidia_version"
                                                    print_nv_drv_dir
                                            elif [ -f "$RUNIMAGEDIR/$nvidia_driver_image" ]
                                                then
                                                    mount_nvidia_driver_image "$RUNIMAGEDIR/$nvidia_driver_image"
                                            elif [ -f "$NVIDIA_DRIVERS_DIR/$nvidia_driver_image" ]
                                                then
                                                    mount_nvidia_driver_image "$NVIDIA_DRIVERS_DIR/$nvidia_driver_image"
                                            elif [ -f "$RUNDIR/nvidia-drivers/$nvidia_version/64/libGLX_nvidia.so.$nvidia_version" ]
                                                then
                                                    nvidia_driver_dir="$RUNDIR/nvidia-drivers/$nvidia_version"
                                                    print_nv_drv_dir
                                            elif [ -f "$RUNDIR/nvidia-drivers/$nvidia_driver_image" ]
                                                then
                                                    mount_nvidia_driver_image "$RUNDIR/nvidia-drivers/$nvidia_driver_image"
                                            fi
                                    fi
                                else
                                    error_msg "Nvidia driver not found in RunImage!"
                                    return 1
                            fi
                            if [ -f "$nvidia_driver_dir/64/libGLX_nvidia.so.$nvidia_version" ]
                                then
                                    nvidia_libs_list="libcuda.so libEGL_nvidia.so libGLESv1_CM_nvidia.so libnvidia-opencl.so \
                                        libGLESv2_nvidia.so libGLX_nvidia.so libnvcuvid.so libnvidia-allocator.so \
                                        libnvidia-cfg.so libnvidia-eglcore.so libnvidia-encode.so libnvidia-fbc.so \
                                        libnvidia-glcore.so libnvidia-glsi.so libnvidia-glvkspirv.so libnvidia-ml.so \
                                        libnvidia-ngx.so libnvidia-opticalflow.so libnvidia-ptxjitcompiler.so libcudadebugger.so \
                                        libnvidia-rtcore.so libnvidia-tls.so libnvidia-vulkan-producer.so libnvoptix.so \
                                        libnvidia-nvvm.so libnvidia-pkcs11.so libnvidia-pkcs11-openssl3.so libnvidia-wayland-client.so \
                                        libnvidia-vksc-core.so libnvidia-gpucomp.so libnvidia-sandboxutils.so"
                                    for lib in ${nvidia_libs_list}
                                        do
                                            if [ -f "$RUNROOTFS/usr/lib/${lib}.${nvidia_version_inside}" ]
                                                then
                                                    NVIDIA_DRIVER_BIND+=("--ro-bind-try"
                                                        "$nvidia_driver_dir/64/${lib}.${nvidia_version}"
                                                        "/usr/lib/${lib}.${nvidia_version_inside}")
                                            fi
                                            if [ -f "$RUNROOTFS/usr/lib32/${lib}.${nvidia_version_inside}" ]
                                                then
                                                    NVIDIA_DRIVER_BIND+=("--ro-bind-try"
                                                        "$nvidia_driver_dir/32/${lib}.${nvidia_version}"
                                                        "/usr/lib32/${lib}.${nvidia_version_inside}")
                                            fi
                                    done
                                    if [ -f "$RUNROOTFS/usr/lib/libnvidia-api.so.1" ]
                                        then
                                            NVIDIA_DRIVER_BIND+=("--ro-bind-try"
                                                "$nvidia_driver_dir/64/libnvidia-api.so.1"
                                                "/usr/lib/libnvidia-api.so.1")
                                    fi
                                    if [ -f "$RUNROOTFS/usr/lib/xorg/modules/drivers/nvidia_drv.so" ]
                                        then
                                            NVIDIA_DRIVER_BIND+=("--ro-bind-try"
                                                "$nvidia_driver_dir/64/nvidia_drv.so"
                                                "/usr/lib/xorg/modules/drivers/nvidia_drv.so")
                                    fi
                                    if [ -f "$RUNROOTFS/usr/lib/nvidia/xorg/libglxserver_nvidia.so.${nvidia_version_inside}" ]
                                        then
                                            NVIDIA_DRIVER_BIND+=("--ro-bind-try"
                                                "$nvidia_driver_dir/64/libglxserver_nvidia.so.${nvidia_version}"
                                                "/usr/lib/nvidia/xorg/libglxserver_nvidia.so.${nvidia_version_inside}")
                                    fi
                                    if [ -f "$RUNROOTFS/usr/lib/vdpau/libvdpau_nvidia.so.${nvidia_version_inside}" ]
                                        then
                                            NVIDIA_DRIVER_BIND+=("--ro-bind-try"
                                                "$nvidia_driver_dir/64/libvdpau_nvidia.so.${nvidia_version}"
                                                "/usr/lib/vdpau/libvdpau_nvidia.so.${nvidia_version_inside}")
                                    fi
                                    if [ -f "$RUNROOTFS/usr/lib32/vdpau/libvdpau_nvidia.so.${nvidia_version_inside}" ]
                                        then
                                            NVIDIA_DRIVER_BIND+=("--ro-bind-try"
                                                "$nvidia_driver_dir/32/libvdpau_nvidia.so.${nvidia_version}"
                                                "/usr/lib32/vdpau/libvdpau_nvidia.so.${nvidia_version_inside}")
                                    fi
                                    if [ -f "$RUNROOTFS/usr/share/egl/egl_external_platform.d/15_nvidia_gbm.json" ]
                                        then
                                            NVIDIA_DRIVER_BIND+=("--ro-bind-try"
                                                "$nvidia_driver_dir/json/15_nvidia_gbm.json"
                                                "/usr/share/egl/egl_external_platform.d/15_nvidia_gbm.json")
                                    fi
                                    if [ -f "$RUNROOTFS/usr/share/glvnd/egl_vendor.d/10_nvidia.json" ]
                                        then
                                            NVIDIA_DRIVER_BIND+=("--ro-bind-try"
                                                "$nvidia_driver_dir/json/10_nvidia.json"
                                                "/usr/share/glvnd/egl_vendor.d/10_nvidia.json")
                                    fi
                                    if [ -f "$RUNROOTFS/usr/share/vulkan/icd.d/nvidia_icd.json" ]
                                        then
                                            NVIDIA_DRIVER_BIND+=("--ro-bind-try"
                                                "$nvidia_driver_dir/json/nvidia_icd.json"
                                                "/usr/share/vulkan/icd.d/nvidia_icd.json")
                                    fi
                                    if [ -f "$RUNROOTFS/usr/share/vulkan/implicit_layer.d/nvidia_layers.json" ]
                                        then
                                            NVIDIA_DRIVER_BIND+=("--ro-bind-try"
                                                "$nvidia_driver_dir/json/nvidia_layers.json"
                                                "/usr/share/vulkan/implicit_layer.d/nvidia_layers.json")
                                    fi
                                    if [ -f "$RUNROOTFS/usr/share/vulkansc/icd.d/nvidia_icd_vksc.json" ]
                                        then
                                            NVIDIA_DRIVER_BIND+=("--ro-bind-try"
                                                "$nvidia_driver_dir/json/nvidia_icd_vksc.json"
                                                "/usr/share/vulkansc/icd.d/nvidia_icd_vksc.json")
                                    fi
                                    if [ -f "$RUNROOTFS/etc/OpenCL/vendors/nvidia.icd" ]
                                        then
                                            NVIDIA_DRIVER_BIND+=("--ro-bind-try"
                                                "$nvidia_driver_dir/conf/nvidia.icd"
                                                "/etc/OpenCL/vendors/nvidia.icd")
                                    fi
                                    if [ -d "$RUNROOTFS/usr/share/nvidia" ]
                                        then
                                            NVIDIA_DRIVER_BIND+=("--ro-bind-try"
                                                "$nvidia_driver_dir/profiles"
                                                "/usr/share/nvidia")
                                    fi
                                    if [ -d "$RUNROOTFS/usr/lib/nvidia/wine" ]
                                        then
                                            NVIDIA_DRIVER_BIND+=("--ro-bind-try"
                                                "$nvidia_driver_dir/wine"
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
                                            NVIDIA_DRIVER_BIND+=("--ro-bind-try" "$nvidia_driver_dir/bin" "/usr/bin/nvidia"
                                                "--ro-bind-try" "$nvidia_driver_dir/64" "/usr/lib/nvidia/64"
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
            elif [[ -d "$1" && ! -n "$(ls -A "$1" 2>/dev/null)" ]]
                then DORM=1
            fi
            if [[ "$DORM" == 1 && -w "$1" ]]
                then
                    if ! rmdir "$1" 2>/dev/null
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
    get_runpids() { gawk -F'/' '{print $(NF-1)}'<<<"$(get_sock '*')" 2>/dev/null ; }
    get_sock() {
        if [ "$act" == "portfw" ]
            then find "$RUNTMPDIR"/$1 -name 'portfw' 2>/dev/null
            else find "$RUNTMPDIR"/$1 -name '*sock' 2>/dev/null
        fi
    }
    attach_act() {
        try_unmount_rundir() {
            if [[ -n "$RUNIMAGE" && ! "$RUNDIR" =~ /*remp[0-9]*$ ]]
                then (sleep 0.3; try_unmount "$RUNDIR") &
            fi
        }
        local ATT_RUNDIRFL="${RUNTMPDIR}/$1/rundir"
        if [ -f "$ATT_RUNDIRFL" ]
            then
                RUNDIRFL="$ATT_RUNDIRFL"
                local ATT_RUNDIR="$(cat "$RUNDIRFL" 2>/dev/null)"
                if [ -d "$ATT_RUNDIR" ]
                    then
                        local ATT_SSRV_ELF="$ATT_RUNDIR/static/ssrv"
                        local ATT_CHISEL="$ATT_RUNDIR/static/chisel"
                        [ -x "$ATT_SSRV_ELF" ] && \
                        SSRV_ELF="$ATT_SSRV_ELF"
                        [ -x "$ATT_CHISEL" ] && \
                        CHISEL="$ATT_CHISEL"
                fi
        fi
        if [ "$act" == "portfw" ]
            then
                info_msg "Port forwarding RunImage RUNPID: $1"
                local RUNPORTFW="$(get_sock "$1")"
                shift
                try_unmount_rundir
                exec "$CHISEL" client "unix:$RUNPORTFW" "$@"
            else
                info_msg "Exec RunImage RUNPID: $1"
                export SSRV_SOCK="unix:$(get_sock "$1")"
                export SSRV_ENV='all-:RIM_*'
                export SSRV_ENV_PIDS="$(get_child_pids "$(cat "$RUNTMPDIR/$1/ssrv.pid" 2>/dev/null)"|head -1)"
                export SSRV_ENV_PIDS="${SSRV_ENV_PIDS:=$(get_child_pids "$(cat "$RUNTMPDIR/$1/tini.pid" 2>/dev/null)"|head -1)}"
                shift
                try_unmount_rundir
                [ "$RIM_EXEC_SAME_PWD" == 1 ] && \
                    export SSRV_CWD="$PWD"
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
                    local runpiddir="$RUNTMPDIR/$runpid"
                    if [[ "$runpid" =~ ^[0-9]+$ && -e "$runpiddir" ]]
                        then
                            if ! kill "$runpid" 2>/dev/null
                                then
                                    kill $(get_child_pids "$runpid" 2>/dev/null) 2>/dev/null && ret=0
                                    sleep 0.1
                                    rm -rf "$runpiddir" 2>/dev/null
                                else ret=0
                            fi
                        else
                            error_msg "RunImage container not found by RUNPID: $runpid"
                            exit 1
                    fi
            done
    elif [ "$1" == 'all' ]
        then
            if ! kill $(get_runpids) 2>/dev/null
                then
                    kill $(get_child_pids $(ls -d "$RUNTMPDIR"/* 2>/dev/null|gawk -F'/' '{print$NF}')) 2>/dev/null && ret=0
                    sleep 0.1
                    rm -rf "$RUNTMPDIR" 2>/dev/null
                else ret=0
            fi
            local MOUNTPOINTS="$(grep -E "$([ -n "$RUNIMAGENAME" ] && \
                echo "$RUNIMAGENAME"||echo "$RUNIMAGEDIR")|.*/mnt/cryptfs.*$RUNIMAGEDIR|$RUNTMPDIR/.*/mnt/nv.*drv|unionfs.*$RUNIMAGEDIR" \
                /proc/self/mounts|grep -v "$RUNDIR"|gawk '{print$2}')"
            if [ -n "$MOUNTPOINTS" ]
                then
                    (IFS=$'\n' ; for unmt in $MOUNTPOINTS
                        do try_unmount "$unmt"
                    done) && ret=0
            fi
    else choose_runpid_and kill 2>/dev/null && ret=0
    fi
    [ "$ret" != 1 ] && info_msg "RunImage successfully killed!"
    return $ret
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
    if [[ -n "$RUNIMAGE" && -e "$RUNPIDDIR/rebuild" && ! -d "$RIM_ROOTFS" ]]
        then try_rebuild_runimage && RIM_KEEP_OVERFS=0
    fi
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
            try_kill "$(get_child_pids "$RUNPID")"
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
            if [ "$FORCE_KILL_PPID" == 1 ]
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

get_child_pids() {
    if [ -n "$1" ]
        then
            local CPIDS="$("${RUNSTATIC}/cpids" "$@" 2>/dev/null)"
            ps -o pid=,cmd= -p $CPIDS 2>/dev/null|\
                grep -v "bash /.*/Run.sh"|gawk '{print$1}'
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
            [ -n "$2" ] && \
            local wait_time="$2"||\
            local wait_time=300
            while is_pid "$RUNPID" && [ "$wait_time" -gt 0 ]
                do
                    if [ -e "$1" ]
                        then return 0
                        else
                            (( wait_time-- ))
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
                    2>/dev/null|grep 'ssrv -srv'|gawk 'NR==1{print$1}')"
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
            "$SSRV_ELF" /var/RunDir/static/chisel server -usock "$RUNPORTFW" -socks5 -reverse 1>/dev/null &
            CHISEL_PID="$!"
            wait_exist "$RUNPORTFW"
            if ! is_pid "$CHISEL_PID"
                then
                    error_msg "Failed to start port forwarding server!"
                    cleanup force
                    exit 1
            fi
            CHISEL_PIDS="$CHISEL_PID"
            if [ "$RIM_SNET_PORTFW" != 1 ]
                then
                    "$CHISEL" client "unix:$RUNPORTFW" $RIM_SNET_PORTFW 1>/dev/null &
                    CHISEL_PID="$!"
                    sleep 0.01
                    if ! is_pid "$CHISEL_PID"
                        then
                            error_msg "Failed to start port forwarding: $RIM_SNET_PORTFW"
                            cleanup force
                            exit 1
                    fi
                    CHISEL_PIDS+=" $CHISEL_PID"
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
            info_msg "Changing a sandbox network TAP IP: $RIM_SNET_TAPIP"
            "$SSRV_ELF" "$RUNSTATIC/bash" -c "$CHANGE_TAPIP"
    fi
    if [[ "$RIM_SNET_DROP_CIDRS" == 1 && -n "$DROP_CIDRS" ]]
        then
            info_msg "Dropping local CIDRs..."
            "$SSRV_ELF" "$RUNSTATIC/bash" -c "$DROP_CIDRS"
    fi
    enable_portfw
}

bwrun() {
    unset EXEC_STATUS
    if [ ! -f "$RUNROOTFS"/lib/ld-musl-*.so.1 ] && \
        [ -f "$RUNROOTFS"/lib/ld-linux-*.so.* ]
        then
            if [ "$RIM_NO_NVIDIA_CHECK" == 1 ]
                then warn_msg "Nvidia driver check is disabled!"
            elif [[ "$RIM_NO_NVIDIA_CHECK" != 1 && ! -n "$NVIDIA_DRIVER_BIND" ]]
                then check_nvidia_driver
            fi
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
            if [[ -d "$OVERFS_DIR" && -d "$BOVERLAY_SRC" && "$RIM_NO_BWRAP_OVERLAY" != 1 ]]
                then
                    BWRAP_EXEC+=(
                        --overlay-src "$BOVERLAY_SRC"
                        --overlay "${OVERFS_DIR}/layers/rootfs"
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
                "${FONTS_BIND[@]}" "${ICONS_BIND[@]}"
                "${BOOT_BIND[@]}" "${THEMES_BIND[@]}"
                "${PKGCACHE_BIND[@]}"
                --setenv INSIDE_RUNIMAGE '1'
                --setenv RUNPID "$RUNPID"
                --setenv PATH "$BIN_PATH"
                --setenv FAKEROOTDONTTRYCHOWN 'true'
                --setenv XDG_CONFIG_DIRS "/etc/xdg:$XDG_CONFIG_DIRS"
                --setenv XDG_DATA_DIRS "/usr/local/share:/usr/share:$XDG_DATA_DIRS"
            )
            [ "$RIM_ROOT" == 1 ] && \
                BWRAP_EXEC+=(--uid 0 --gid 0)
            [ -n "$LIB_PATH" ] && \
                BWRAP_EXEC+=(--setenv LD_LIBRARY_PATH "$LIB_PATH")
            BWRAP_EXEC+=(/var/RunDir/static/tini -a -k SIGTERM -s -p SIGTERM -g --)
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
                            for cidr in $(ip -o -4 a|grep -wv lo|gawk '{print$4}')
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
                        done; try_kill "$SLIRP_PID $CHISEL_PIDS"
                    }
                    bwin() {
                        unfbwin() { unset -f bwin wait_exist is_pid is_snet ; unset "${!RIM_@}" ; }
                        [[ "$A_EXEC_ARGS" =~ ^declare ]] && \
                        eval "$A_EXEC_ARGS" && unset A_EXEC_ARGS
                        [[ "$A_BWRUNARGS" =~ ^declare ]] && \
                        eval "$A_BWRUNARGS" && unset A_BWRUNARGS
                        (unfbwin ; exec setsid /var/RunDir/static/ssrv -srv -env all 1>/dev/null) &
                        wait_exist "$SSRV_PID_FILE"
                        is_snet && sleep 0.1
                        if [[ "$RUNTTY" =~ 'tty' && "$RIM_TTY_ALLOC_PTY" == 1 ]]
                            then unfbwin ; /var/RunDir/static/ssrv "${EXEC_ARGS[@]}" "${BWRUNARGS[@]}"
                            else unfbwin ; unset "${!SSRV_@}" ; "${EXEC_ARGS[@]}" "${BWRUNARGS[@]}"
                        fi
                        return $?
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
                    BWRAP_EXEC+=(/var/RunDir/static/bash -c bwin)
                    if [[ "${BWRAP_EXEC[1]}" =~ --overlay-src ]]
                        then
                            try_bwrap_overlay() {
                                unset -f try_bwrap_overlay
                                [[ "$A_BWRAP_EXEC" =~ ^declare ]] && \
                                eval "$A_BWRAP_EXEC" && unset A_BWRAP_EXEC
                                "${BWRAP_EXEC[@]}" 8>"$BWINFFL"
                                local EXEC_STATUS=$?
                                if [ -f "$RUNPIDDIR/bwerr" ]
                                    then
                                        if grep -qio "bwrap: can't make overlay mount" "$RUNPIDDIR/bwerr" &>/dev/null
                                            then
                                                sleep 0.05 &>/dev/null
                                                if is_pid "$RUNPID" &>/dev/null
                                                    then
                                                        BWRAP_EXEC[1]='--bind'
                                                        BWRAP_EXEC[2]="$RUNROOTFS"
                                                        unset BWRAP_EXEC[3] BWRAP_EXEC[4] BWRAP_EXEC[5]
                                                        "${BWRAP_EXEC[@]}" 8>"$BWINFFL"
                                                        local EXEC_STATUS=$?
                                                fi
                                            else cat "$RUNPIDDIR/bwerr" 1>&2
                                        fi
                                fi
                                return $EXEC_STATUS
                            }
                            export A_BWRAP_EXEC="$(declare -p BWRAP_EXEC 2>/dev/null)"
                            export -f try_bwrap_overlay
                            "$RUNSTATIC/bash" -c try_bwrap_overlay
                        else
                            "${BWRAP_EXEC[@]}" 8>"$BWINFFL"
                    fi
                    local EXEC_STATUS="$?"
                else
                    RIM_ENVS="$(tr ' ' ','<<<"${!RIM_@}")"
                    BWRAP_EXEC+=(/var/RunDir/static/ssrv -srv -env all)
                    if [[ "${BWRAP_EXEC[1]}" =~ --overlay-src ]]
                        then
                            try_bwrap_overlay() {
                                unset -f try_bwrap_overlay
                                [[ "$A_BWRAP_EXEC" =~ ^declare ]] && \
                                eval "$A_BWRAP_EXEC" && unset A_BWRAP_EXEC
                                (unset -f is_pid ; exec "${BWRAP_EXEC[@]}" 8>"$BWINFFL" 2>"$RUNPIDDIR/bwerr" 1>/dev/null)
                                local EXEC_STATUS=$?
                                if [ -f "$RUNPIDDIR/bwerr" ]
                                    then
                                        if grep -qio "bwrap: can't make overlay mount" "$RUNPIDDIR/bwerr" &>/dev/null
                                            then
                                                sleep 0.05 &>/dev/null
                                                if is_pid "$RUNPID" &>/dev/null
                                                    then
                                                        unset -f is_pid
                                                        BWRAP_EXEC[1]='--bind'
                                                        BWRAP_EXEC[2]="$RUNROOTFS"
                                                        unset BWRAP_EXEC[3] BWRAP_EXEC[4] BWRAP_EXEC[5]
                                                        "${BWRAP_EXEC[@]}" 8>"$BWINFFL" 1>/dev/null
                                                        local EXEC_STATUS=$?
                                                fi
                                            else cat "$RUNPIDDIR/bwerr" 1>&2
                                        fi
                                fi
                                return $EXEC_STATUS
                            }
                            export A_BWRAP_EXEC="$(declare -p BWRAP_EXEC 2>/dev/null)"
                            export -f try_bwrap_overlay is_pid
                            SSRV_UENV="$RIM_ENVS" "$RUNSTATIC/bash" -c try_bwrap_overlay &
                        else
                            SSRV_UENV="$RIM_ENVS" "${BWRAP_EXEC[@]}" 8>"$BWINFFL" 1>/dev/null &
                    fi
                    wait_exist "$SSRV_PID_FILE"
                    export_ssrv_pid
                    if is_snet
                        then create_sandbox_net
                    elif is_nonet
                        then enable_portfw
                    fi
            fi
    fi
    if [ ! -n "$EXEC_STATUS" ]
        then
            "$SSRV_ELF" "${RIM_EXEC_ARGS[@]}" "$@"
            local EXEC_STATUS="$?"
    fi
    if [ "$RIM_WAIT_RPIDS_EXIT" != 1 ]
        then
            [ -f "$BWINFFL" ] && \
                rm -f "$BWINFFL" 2>/dev/null
            kill $SSRV_PID 2>/dev/null
            [ -e "$SSRV_SOCK_PATH" ] && \
                rm -f "$SSRV_SOCK_PATH" 2>/dev/null
    fi
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
                                try_kill "$(lsof -n "$RMOVERFS_MNT" 2>/dev/null|sed 1d|gawk '{print$2}'|sort -u)"
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
                            if [ -n "$overfs_id" ]
                                then
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
                            fi
                    done
                else
                    error_msg "Specify the OverlayFS ID!"
            fi
        else
            error_msg "OverlayFS not found!"
    fi
    return $ret
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
    bwrun find /usr/bin/ /bin/ -executable -type f -maxdepth 1 \
    2>/dev/null|sed 's|/usr/bin/||g;s|/bin/||g'|sort -u
}

print_version() {
    info_msg "RunImage version: ${RED}v$RUNIMAGE_VERSION"
    info_msg "RootFS version: ${RED}v$RUNROOTFS_VERSION"
    info_msg "Static version: ${RED}$RUNSTATIC_VERSION"
    [ -n "$RUNRUNTIME_VERSION" ] && \
        info_msg "RunImage runtime version: ${RED}$RUNRUNTIME_VERSION"
}

run_update() {
    info_msg "RunImage update"
    RIM_ROOT=1 RIM_QUIET_MODE=1 \
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
    [ -f "$1" ] && \
    if grep -qo ".*:x:$EUID:" "$1" &>/dev/null
        then sed -i "s|.*:x:$EUID:.*|$RUNUSER:x:$EUID:0:[^_^]:$HOME:/bin/sh|g" "$1"
        else [ -w "$1" ] && echo "$RUNUSER:x:$EUID:0:[^_^]:$HOME:/bin/sh" >> "$1"
    fi
}

add_unshared_group() {
    [ -f "$1" ] && \
    if grep -o ".*:x:$EGID:" "$1" &>/dev/null
        then sed -i "s|.*:x:$EGID:.*|$RUNGROUP:x:$EGID:|g" "$1"
        else [ -w "$1" ] && echo "$RUNGROUP:x:$EGID:" >> "$1"
    fi
}

try_rebuild_runimage() {
    if [ -n "$1" ]||\
        [[ -n "$RUNIMAGE" && "$REBUILD_RUNIMAGE" == 1 ]]||\
        [[ -n "$RUNIMAGE" && -e "$RUNPIDDIR/rebuild" ]]
        then
            rm -f "$RUNPIDDIR/rebuild"
            cd "$RUNIMAGEDIR"
            run_build "$@"
            local ret="$?"
            cd "$OLDPWD"
            return $ret
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
            if "$GOCRYPTFS" --passwd "$CRYPTFS_DIR"
                then
                    export RIM_CMPRS_LVL=1 RIM_CMPRS_ALGO=zstd
                    try_rebuild_runimage "$@"
                    exit $?
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
                                "$RUNDIR/sharun/lib4bin" -s -p -g -d "$RUNDIR/sharun" \
                                    $(cat "$RUNDIR/sharun/bin.list")
                            }
                            export -f upd_sharun
                            if bwrun /var/RunDir/static/bash -c upd_sharun
                                then
                                    info_msg "Encrypting RunImage rootfs..."
                                    if chmod u+rw -R "$RUNROOTFS" && cp -rf "$RUNROOTFS"/{.,}* "$CRYPTFS_MNT"/
                                        then
                                            rm -rf "$RUNROOTFS"/{.,}*
                                            export RUNROOTFS="$CRYPTFS_MNT"
                                            export RIM_CMPRS_LVL=1 RIM_CMPRS_ALGO=zstd
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
            if cp -rf "$CRYPTFS_MNT"/{.,}* "$RUNROOTFS"/
                then
                    rm -rf "$BRUNDIR/sharun/shared"/*
                    if (for dir in bin lib
                        do ln -sfr "$RUNROOTFS/$dir" "$BRUNDIR/sharun/shared"/
                    done)
                        then
                            rm -rf "$CRYPTFS_DIR"
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

rim_start() {
    if [ -n "$RIM_AUTORUN" ]
        then
            [ "$ARG1" != "$(basename "$RUNSRC")" ] && [[ "$ARG1" == "$AUTORUN0ARG" ||\
              "$ARG1" == "$(basename "${RIM_CONFIG%.rcfg}")" ||\
              "$ARG1" == "$(basename "${RUNIMAGE_INTERNAL_CONFIG%.rcfg}")" ]] && \
                ARGS=("${ARGS[@]:1}")
            [ -n "$REALAUTORUN" ]||check_autorun
            if [ "${#RIM_AUTORUN[@]}" == 1 ]
                then "$@" $RIM_AUTORUN "${ARGS[@]}"
                else "$@" "${RIM_AUTORUN[@]}" "${ARGS[@]}"
            fi
        else
            if [[ ! -n "$ARG1" && ! -n "$RIM_EXEC_ARGS" ]]
                then "$@" "${RIM_SHELL[@]}"
                else "$@" "${ARGS[@]}"
            fi
    fi
}

check_autorun() {
    if [[ -n "$RIM_AUTORUN" && "$RIM_AUTORUN" != 0 ]]
        then
            AUTORUN0ARG=($RIM_AUTORUN)
            info_msg "Autorun mode: ${RIM_AUTORUN[@]}"
            is_rio_running && \
            archeck_cmd=(run_attach exec "$SSRV_RUNPID")||\
            archeck_cmd=(bwrun)
            OLD_IFS="$IFS"
            IFS=$'\n'
            WHICH_AUTORUN0ARG=($(IFS="$OLD_IFS" \
                RIM_NO_NVIDIA_CHECK=1 RIM_WAIT_RPIDS_EXIT=0 \
                RIM_QUIET_MODE=1 RIM_SANDBOX_NET=0 RIM_NO_BWRAP_OVERLAY=1 \
                "${archeck_cmd[@]}" which -a "$AUTORUN0ARG" </dev/null))
            IFS="$OLD_IFS"
            unset REALAUTORUN
            for exe in "${WHICH_AUTORUN0ARG[@]}"
                do
                    [ "$(realpath "$exe")" != "$REALRUNSRC" ] && \
                        REALAUTORUN="$exe" && break
            done
            if [ -n "$REALAUTORUN" ]
                then
                    export RUNSRCNAME="$(basename "$AUTORUN0ARG")"
                    export RIM_AUTORUN="$REALAUTORUN"
                else
                    error_msg "$AUTORUN0ARG not found in PATH!"
                    cleanup force
                    exit 1
            fi
    fi
}

is_rio_running() {
    [[ -n "$SSRV_RUNPID" && -e "$SSRV_SOCK_PATH" ]] && \
        is_pid "$SSRV_RUNPID"
}

run_build() {
    if [ -d "$RIM_ROOTFS" ]
        then bwrun rim-build "$@"
        else "$RUNSTATIC/bash" "$RUNUTILS/rim-build" "$@"
    fi
    if [ "$?" != 0 ]
        then [[ -d "$OVERFS_DIR" && "$RIM_KEEP_OVERFS" == 0 ]] && RIM_KEEP_OVERFS=1
    fi
}

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
    RIM_SHARE_ICONS=0
    RIM_UNSHARE_HOME=1
    RIM_SHARE_THEMES=0
    RIM_SANDBOX_HOME=0
    RIM_PORTABLE_HOME=0
    RIM_UNSHARE_USERS=1
    RIM_UNSHARE_HOSTS=1
    RIM_WAIT_RPIDS_EXIT=0
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
    RIM_DINTEG=0
    if [[ -n "$RUNIMAGE" && ! -n "$RIM_OVERFS_ID" && ! -d "$RIM_ROOTFS" ]]
        then
            RIM_OVERFS_MODE=1
            RIM_KEEP_OVERFS=0
            REBUILD_RUNIMAGE=1
            RIM_OVERFS_ID="${1}$(date +"%H%M%S").$RUNPID"
    fi
}

print_help() {
    RUNHOSTNAME="$(uname -a|gawk '{print$2}')"
    echo -e "
${GREEN}RunImage ${RED}v${RUNIMAGE_VERSION} ${GREEN}by $DEVELOPERS
    ${RED}Usage:
        $RED┌──[$GREEN$RUNUSER$YELLOW@$BLUE${RUNHOSTNAME}$RED]─[$GREEN$PWD$RED]
        $RED└──╼ \$$GREEN $([ -n "$ARG0" ] && echo "$ARG0"||echo "$0") ${BLUE}{args} $GREEN{executable} $YELLOW{executable args}

        ${BLUE}rim-help   $GREEN                    Show this usage info
        ${BLUE}rim-version$GREEN                    Show RunImage, rootfs, static, runtime version
        ${BLUE}rim-pkgls  $GREEN                    Show packages installed in RunImage
        ${BLUE}rim-binls  $GREEN                    Show executables in RunImage
        ${BLUE}rim-shell  $YELLOW  {args}$GREEN            Run RunImage shell or execute a command in RunImage shell
        ${BLUE}rim-desktop$YELLOW  {args}$GREEN            Launch RunImage desktop
        ${BLUE}rim-ofsls$GREEN                      Show the list of RunImage OverlayFS
        ${BLUE}rim-ofsrm  $YELLOW  {id id ...|all}$GREEN   Remove OverlayFS
        ${BLUE}rim-build  $YELLOW  {args}$GREEN            Build new RunImage container
        ${BLUE}rim-update $YELLOW  {args}$GREEN            Update packages and rebuild RunImage
        ${BLUE}rim-kill   $YELLOW  {RUNPIDs|all}$GREEN     Kill running RunImage containers
        ${BLUE}rim-psmon$YELLOW    {args} {RUNPIDs}$GREEN  Monitoring of processes running in RunImage containers
        ${BLUE}rim-exec $YELLOW    {RUNPID} {args}$GREEN   Exec command in running container
        ${BLUE}rim-portfw $YELLOW  {RUNPID} {args}$GREEN   Forward additional ports
        ${BLUE}rim-dinteg $YELLOW  {args}$GREEN            Desktop integration
        ${BLUE}rim-shrink $YELLOW  {args}$GREEN            Shrink RunImage rootfs
        ${BLUE}rim-bootstrap $YELLOW{pkg pkg}$GREEN        Bootstrap new RunImage
        ${BLUE}rim-encfs $YELLOW   {build args}$GREEN      Encrypt RunImage rootfs
        ${BLUE}rim-decfs $YELLOW   {build args}$GREEN      Decrypt RunImage rootfs
        ${BLUE}rim-enc-passwd $YELLOW{build args}$GREEN    Change decrypt password for encrypted RunImage rootfs

    ${RED}Only for not extracted (RunImage runtime options):
        ${BLUE}--runtime-extract$YELLOW {pattern}$GREEN          Extract content from embedded filesystem image
        ${BLUE}--runtime-extract-and-run $YELLOW{args}$GREEN     Run RunImage after extraction without using FUSE
        ${BLUE}--runtime-help$GREEN                       Show RunImage runtime help
        ${BLUE}--runtime-offset$GREEN                     Print byte offset to start of embedded
        ${BLUE}--runtime-portable-home$GREEN              Create a portable home folder to use as ${YELLOW}\$HOME$GREEN
        ${BLUE}--runtime-portable-config$GREEN            Create a portable config folder to use as ${YELLOW}\$XDG_CONFIG_HOME$GREEN
        ${BLUE}--runtime-version$GREEN                    Print version of RunImage runtime
        ${BLUE}--runtime-mount$GREEN                      Mount embedded filesystem image and print
                                                mount point and wait for kill with Ctrl-C
        ${BLUE}--runtime-squashfuse $YELLOW{args}$GREEN          Launch squashfuse
        ${BLUE}--runtime-unsquashfs $YELLOW{args}$GREEN          Launch unsquashfs
        ${BLUE}--runtime-mksquashfs $YELLOW{args}$GREEN          Launch mksquashfs
        ${BLUE}--runtime-dwarfs     $YELLOW{args}$GREEN          Launch dwarfs
        ${BLUE}--runtime-dwarfsck   $YELLOW{args}$GREEN          Launch dwarfsck
        ${BLUE}--runtime-mkdwarfs   $YELLOW{args}$GREEN          Launch mkdwarfs
        ${BLUE}--runtime-dwarfsextract $YELLOW{args}$GREEN       Launch dwarfsextract

    ${RED}Configuration environment variables:
        ${YELLOW}RIM_ROOTFS$GREEN=/path/rootfs                  Specifies custom rootfs (0 to disable)
        ${YELLOW}RIM_NO_NET$GREEN=1                             Disables network access
        ${YELLOW}RIM_TMP_HOME$GREEN=1                           Creates tmpfs /home/${YELLOW}\$USER${GREEN} and /root in RAM and uses it as ${YELLOW}\$HOME
        ${YELLOW}RIM_TMP_HOME_DL$GREEN=1                        As above, but with binding ${YELLOW}\$HOME${GREEN}/Downloads dir
        ${YELLOW}RIM_SANDBOX_HOME$GREEN=1                       Creates sandbox home dir
        ${YELLOW}RIM_SANDBOX_HOME_DL$GREEN=1                    As above, but with binding ${YELLOW}\$HOME${GREEN}/Downloads dir
        ${YELLOW}RIM_SANDBOX_HOME_DIR$GREEN=/path/dir           Specifies sandbox home dir
        ${YELLOW}RIM_UNSHARE_HOME$GREEN=1                       Unshares host home dir
        ${YELLOW}RIM_UNSHARE_HOME_DL$GREEN=1                    As above, but with binding ${YELLOW}\$HOME${GREEN}/Downloads dir
        ${YELLOW}RIM_PORTABLE_HOME$GREEN=1                      Creates a portable home dir and uses it as ${YELLOW}\$HOME
        ${YELLOW}RIM_PORTABLE_HOME_DIR$GREEN=/path/dir          Specifies a portable home dir and uses it as ${YELLOW}\$HOME
        ${YELLOW}RIM_PORTABLE_CONFIG$GREEN=1                    Creates a portable config dir and uses it as ${YELLOW}\$XDG_CONFIG_HOME
        ${YELLOW}RIM_NO_CLEANUP$GREEN=1                         Disables unmounting and cleanup mountpoints
        ${YELLOW}RIM_UNSHARE_PIDS$GREEN=1                       Unshares all host processes
        ${YELLOW}RIM_UNSHARE_USERS$GREEN=1                      Don't bind-mount /etc/{passwd,group}
        ${YELLOW}RIM_UNSHARE_HOSTNAME$GREEN=1                   Unshares UTS namespace and hostname
        ${YELLOW}RIM_UNSHARE_HOSTS$GREEN=1                      Unshares host /etc/hosts
        ${YELLOW}RIM_UNSHARE_RESOLVCONF$GREEN=1                 Unshares host /etc/resolv.conf
        ${YELLOW}RIM_UNSHARE_RUN$GREEN=1                        Unshares host /run
        ${YELLOW}RIM_SHARE_SYSTEMD$GREEN=1                      Shares host SystemD
        ${YELLOW}RIM_UNSHARE_DBUS$GREEN=1                       Unshares host DBUS
        ${YELLOW}RIM_UNSHARE_UDEV$GREEN=1                       Unshares host UDEV (/run/udev)
        ${YELLOW}RIM_UNSHARE_XDGRUN$GREEN=1                     Unshares host ${YELLOW}\$XDG_RUNTIME_DIR$GREEN
        ${YELLOW}RIM_UNSHARE_XDGSOUND$GREEN=1                   Unshares host ${YELLOW}\$XDG_RUNTIME_DIR$GREEN sound sockets
        ${YELLOW}RIM_UNSHARE_MODULES$GREEN=1                    Unshares host kernel modules (/usr/lib/modules)
        ${YELLOW}RIM_UNSHARE_LOCALTIME$GREEN=1                  Unshares host localtime (/etc/localtime)
        ${YELLOW}RIM_UNSHARE_NSS$GREEN=1                        Unshares host NSS (/etc/nsswitch.conf)
        ${YELLOW}RIM_UNSHARE_TMP$GREEN=1                        Unshares host /tmp
        ${YELLOW}RIM_UNSHARE_TMPX11UNIX$GREEN=1                 Unshares host /tmp/.X11-unix
        ${YELLOW}RIM_UNSHARE_DEF_MOUNTS$GREEN=1                 Unshares default mount points (/mnt /media /run/media)
        ${YELLOW}RIM_SHARE_BOOT$GREEN=1                         Shares host /boot
        ${YELLOW}RIM_SHARE_ICONS$GREEN=1                        Shares host /usr/share/icons
        ${YELLOW}RIM_SHARE_FONTS$GREEN=1                        Shares host /usr/share/fonts
        ${YELLOW}RIM_SHARE_THEMES$GREEN=1                       Shares host /usr/share/themes
        ${YELLOW}RIM_SHARE_PKGCACHE$GREEN=1                     Shares host packages cache
        ${YELLOW}RIM_BIND$GREEN=/path:/path,/path1:/path1       Binds specified paths to the container
        ${YELLOW}RIM_BIND_PWD$GREEN=1                           Binds ${YELLOW}\$PWD$GREEN to the container
        ${YELLOW}RIM_NO_NVIDIA_CHECK$GREEN=1                    Disables checking the nvidia driver version
        ${YELLOW}RIM_SYS_NVLIBS$GREEN=1                         Try to use system Nvidia libraries
        ${YELLOW}RIM_NO_32BIT_NVLIBS_CHECK$GREEN=1              Disable 32-bit Nvidia libraries check
        ${YELLOW}RIM_NVIDIA_DRIVERS_DIR$GREEN=/path/dir         Specifies custom Nvidia driver images dir
        ${YELLOW}RIM_CACHEDIR$GREEN=/path/dir                   Specifies custom RunImage cache dir
        ${YELLOW}RIM_OVERFSDIR$GREEN=/path/dir                  Specifies custom RunImage OverlayFS dir
        ${YELLOW}RIM_OVERFS_MODE$GREEN=1                        Enables OverlayFS mode
        ${YELLOW}RIM_NO_BWRAP_OVERLAY$GREEN=1                   Disables Bubblewrap overlay for OverlayFS mode
        ${YELLOW}RIM_NO_CRYPTFS_MOUNT$GREEN=1                   Disables mount encrypted RunImage rootfs
        ${YELLOW}RIM_KEEP_OVERFS$GREEN=1                        Enables OverlayFS mode with saving after closing RunImage
        ${YELLOW}RIM_OVERFS_ID$GREEN=ID                         Specifies the OverlayFS ID
        ${YELLOW}RIM_SHELL$GREEN=shell                          Selects ${YELLOW}\$SHELL$GREEN in RunImage
        ${YELLOW}RIM_NO_CAP$GREEN=1                             Disables Bubblewrap capabilities (Default: ALL, drop CAP_SYS_NICE)
                                                     you can also use nocap in RunImage
        ${YELLOW}RIM_IN_SAME_PTY$GREEN=1                        Start shell session in same PTY
        ${YELLOW}RIM_TTY_ALLOC_PTY$GREEN=1                      Allocate PTY for shell session on TTY
        ${YELLOW}RIM_AUTORUN$GREEN='{executable} {args}'        Autorun mode for executable from PATH (0 to disable)
        ${YELLOW}RIM_RUN_IN_ONE$GREEN=1                         Execute commands in one container
        ${YELLOW}RIM_ALLOW_ROOT$GREEN=1                         Allows to run RunImage under root user
        ${YELLOW}RIM_QUIET_MODE$GREEN=1                         Disables all non-error RunImage messages
        ${YELLOW}RIM_NO_WARN$GREEN=1                            Disables all warning RunImage messages
        ${YELLOW}RIM_NOTIFY$GREEN=1                             Enables non-error RunImage notification
        ${YELLOW}RUNTIME_EXTRACT_AND_RUN$GREEN=1                Run RunImage after extraction without using FUSE
        ${YELLOW}TMPDIR$GREEN=/path/TMPDIR                      Used for extract and run options
        ${YELLOW}RIM_CONFIG$GREEN=/path/config.rcfg             RunImage сonfiguration file (0 to disable)
        ${YELLOW}RIM_ENABLE_HOSTEXEC$GREEN=1                    Enables the ability to execute commands at the host level
        ${YELLOW}RIM_HOST_TOOLS$GREEN=cmd,cmd                   Enables specified commands from the host (0 to disable)
        ${YELLOW}RIM_HOST_XDG_OPEN$GREEN=1                      Enables xdg-open from the host
        ${YELLOW}RIM_WAIT_RPIDS_EXIT$GREEN=1                    Wait for all processes to exit
        ${YELLOW}RIM_EXEC_SAME_PWD$GREEN=1                      Use same ${YELLOW}\$PWD$GREEN for rim-exec and hostexec
        ${YELLOW}RIM_SANDBOX_NET$GREEN=1                        Creates a network sandbox
        ${YELLOW}RIM_SNET_SHARE_HOST$GREEN=1                    Creates a network sandbox with access to host loopback
        ${YELLOW}RIM_SNET_CIDR$GREEN=11.22.33.0/24              Specifies TAP iface subnet in network sandbox (Def: 10.0.2.0/24)
        ${YELLOW}RIM_SNET_TAPNAME$GREEN=tap0                    Specifies TAP iface name in network sandbox (Def: eth0)
        ${YELLOW}RIM_SNET_MAC$GREEN=B6:40:E0:8B:A6:D7           Specifies TAP iface MAC in network sandbox (Def: random)
        ${YELLOW}RIM_SNET_MTU$GREEN=65520                       Specifies TAP iface MTU in network sandbox (Def: 1500)
        ${YELLOW}RIM_SNET_TAPIP$GREEN=11.22.33.44               For set TAP iface IP in network sandbox mode (Def: 10.0.2.100)
        ${YELLOW}RIM_SNET_PORTFW$GREEN='2222:22 R:53:53/UDP'    Enables port forwarding in network sandbox mode (1 to enable)
        ${YELLOW}RIM_SNET_DROP_CIDRS$GREEN=1                    Drop access to host CIDR's in network sandbox mode
        ${YELLOW}RIM_HOSTS_FILE$GREEN=/path/hosts               Binds specified file to /etc/hosts (0 to disable)
        ${YELLOW}RIM_RESOLVCONF_FILE$GREEN=/path/resolv.conf    Binds specified file to /etc/resolv.conf (0 to disable)
        ${YELLOW}RIM_BWRAP_ARGS$GREEN+=()                       Array with Bubblewrap arguments (for config file)
        ${YELLOW}RIM_EXEC_ARGS$GREEN+=()                        Array with Bubblewrap exec arguments (for config file)
        ${YELLOW}RIM_CRYPTFS_PASSFILE$GREEN=/path/passfile      Specifies passfile for decrypt encrypted RunImage rootfs
        ${YELLOW}RIM_XORG_CONF$GREEN=/path/xorg.conf            Binds xorg.conf to /etc/X11/xorg.conf in RunImage (0 to disable)
                                                     (Default: /etc/X11/xorg.conf bind from the system)
        ${YELLOW}RIM_SYS_BWRAP$GREEN=1                          Using system ${BLUE}bwrap
        ${YELLOW}RIM_SYS_SQFUSE$GREEN=1                         Using system ${BLUE}squashfuse
        ${YELLOW}RIM_SYS_UNSQFS$GREEN=1                         Using system ${BLUE}unsquashfs
        ${YELLOW}RIM_SYS_MKSQFS$GREEN=1                         Using system ${BLUE}mksquashfs
        ${YELLOW}RIM_SYS_UNIONFS$GREEN=1                        Using system ${BLUE}unionfs
        ${YELLOW}RIM_SYS_SLIRP$GREEN=1                          Using system ${BLUE}slirp4netns
        ${YELLOW}RIM_SYS_GOCRYPTFS$GREEN=1                      Using system ${BLUE}gocryptfs
        ${YELLOW}RIM_SYS_TOOLS$GREEN=1                          Use all binaries from the system
                                                 If they are not found in the system - auto return to the built-in
        ${BLUE}rim-build:
        ${YELLOW}RIM_KEEP_OLD_BUILD$GREEN=1                     Creates a backup of the old RunImage when building a new one
        ${YELLOW}RIM_CMPRS_FS$GREEN={sqfs|dwfs}                 Specifies the compression filesystem for RunImage build
        ${YELLOW}RIM_CMPRS_BSIZE$GREEN={1M|20}                  Specifies the compression filesystem block size for RunImage build
        ${YELLOW}RIM_CMPRS_ALGO$GREEN={zstd|xz|lz4}             Specifies the compression algo for RunImage build
        ${YELLOW}RIM_CMPRS_LVL$GREEN={1-22|1-9|1-12}            Specifies the compression ratio for RunImage build
        ${YELLOW}RIM_BUILD_DWFS_HFILE$GREEN=/path               DwarFS hotness list file (Default: $RUNIMAGEDIR/dwarfs.prof) (0 to disable)
        ${BLUE}rim-update:
        ${YELLOW}RIM_UPDATE_SHRINK$GREEN=1                      Run rim-shrink --all after update
        ${YELLOW}RIM_UPDATE_CLEANUP$GREEN=1                     Run rim-shrink --pkgcache after update
        ${BLUE}rim-dinteg:
        ${YELLOW}RIM_DINTEG$GREEN=1                             Enables desktop integration pacman hook
        ${YELLOW}RIM_DINTEG_MIME$GREEN=1                        Desktop integration with MIME types
        ${YELLOW}RIM_DINTEG_DIR$GREEN=/path                     Desktop integration directory (Default: $HOME/.local/share)
        ${BLUE}rim-desktop:
        ${YELLOW}RIM_XEPHYR_SIZE$GREEN=HEIGHTxWIDTH             Sets RunImage desktop resolution (Default: 1600x900)
        ${YELLOW}RIM_DESKTOP_DISPLAY$GREEN=9999                 Sets RunImage desktop ${YELLOW}\$DISPLAY$GREEN (Default: 1337)
        ${YELLOW}RIM_XEPHYR_FULLSCREEN$GREEN=1                  Starts RunImage desktop in full screen mode
        ${YELLOW}RIM_DESKTOP_UNCLIP$GREEN=1                     Disables clipboard synchronization for RunImage desktop
        ${BLUE}rim-shrink:
        ${YELLOW}RIM_SHRINK_ALL$GREEN=1                         Shrink all
        ${YELLOW}RIM_SHRINK_BACK$GREEN=1                        Shrink backup files '*.old' '*.back'
        ${YELLOW}RIM_SHRINK_STATICLIBS$GREEN=1                  Shrink static libs '*.a'
        ${YELLOW}RIM_SHRINK_DOCS$GREEN=1                        Shrink /usr/share/{man,doc,help,info,gtk-doc} and '*.md' 'README*'
        ${YELLOW}RIM_SHRINK_STRIP$GREEN=1                       Strip all debugging symbols & sections
        ${YELLOW}RIM_SHRINK_LOCALES$GREEN=1                     Shrink all locales except uk ru en en_US
        ${YELLOW}RIM_SHRINK_OBJECTS$GREEN=1                     Shrink object files '*.o'
        ${YELLOW}RIM_SHRINK_PKGCACHE$GREEN=1                    Shrink packages cache
        ${YELLOW}RIM_SHRINK_SRC$GREEN=1                         Shrink source code files for build
        ${YELLOW}RIM_SHRINK_PYCACHE$GREEN=1                     Shrink '__pycache__' directories
    $RESETCOLOR"
}

trap cleanup EXIT

if [[ "$EUID" == 0 && "$RIM_ALLOW_ROOT" != 1 && "$INSIDE_RUNIMAGE" != 1 ]]
    then
        error_msg "root user is not allowed!"
        console_info_notify
        echo -e "${RED}\t\t\tDo not run RunImage as root!"
        echo -e "If you really need to run it as root set the ${YELLOW}RIM_ALLOW_ROOT${GREEN}=1 ${RED}environment variable.$RESETCOLOR"
        exit 1
fi

if [ "$RIM_AUTORUN" != 0 ]
    then
        if [[ -n "$RIM_AUTORUN" && "$RUNSRCNAME" =~ ^(Run|runimage).* ]]
            then
                export RUNSRCNAME="$(basename "$RIM_AUTORUN")"
        elif [[ "${RUNSRCNAME,,}" =~ .*\.(runimage|rim)$ ]]
            then
                export RUNSRCNAME="$(sed 's|\.runimage$||i;s|\.rim$||i'<<<"$RUNSRCNAME")"
                export RIM_AUTORUN="$RUNSRCNAME"
        elif [[ ! "$RUNSRCNAME" =~ (Run|runimage).* ]]
            then
                export RIM_AUTORUN="$RUNSRCNAME"
        fi
fi

ARGS=("$@")
if [[ -n "$1" && "$1" != 'rim-'* ]] && [[ ! -n "$RIM_AUTORUN" || "$RIM_AUTORUN" == 0 ]]
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
        unset RIM_AUTORUN
        case "${ARGS[0]}" in
            rim-shrink|rim-dinteg|rim-bootstrap);;
            *) ARGS=("${ARGS[@]:1}") ;;
        esac
elif [[ "$RUNSRCNAME" == 'rim-'* ]]
    then ARG1="$RUNSRCNAME"
fi

case "$ARG1" in
    rim-psmon   ) set_default_option ; RIM_TMP_HOME=1
                    RIM_UNSHARE_PIDS=0 ; RIM_CONFIG=0
                    export SSRV_SOCK="unix:$RUNPIDDIR/rmp"
                    RIM_QUIET_MODE=1
                    RIM_DINTEG=0 ;;
    rim-kill   |\
    rim-help   |\
    rim-ofsls   ) set_default_option ; RIM_NO_CRYPTFS_MOUNT=1 ; RIM_CONFIG=0
                  RIM_DINTEG=0 ;;
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
        if [[ -f "$RIM_CONFIG" && "$RIM_CONFIG" =~ .*\.rcfg$ ]]
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

if [ "$RIM_ROOTFS" != 0 ]
    then
        [[ ! -d "$RIM_ROOTFS" && -d "$RUNIMAGEDIR/rootfs" ]] && \
            export RIM_ROOTFS="$RUNIMAGEDIR/rootfs"
        if [ -d "$RIM_ROOTFS" ]
            then
                info_msg "Found custom rootfs: '$RIM_ROOTFS'"
                export RUNROOTFS="$RIM_ROOTFS"
        fi
fi

[[ -n "$RIM_CACHEDIR" && ! -d "$RIM_CACHEDIR" ]] && \
    try_mkdir "$RIM_CACHEDIR"
[ -d "$RIM_CACHEDIR" ] && \
RUNCACHEDIR="$RIM_CACHEDIR"||\
RUNCACHEDIR="$RUNIMAGEDIR/cache"
export RUNCACHEDIR

[[ -n "$RIM_OVERFSDIR" && ! -d "$RIM_OVERFSDIR" ]] && \
    try_mkdir "$RIM_OVERFSDIR"
[ -d "$RIM_OVERFSDIR" ] && \
RUNOVERFSDIR="$RIM_OVERFSDIR"||\
RUNOVERFSDIR="$RUNIMAGEDIR/overlayfs"
export RUNOVERFSDIR

RUNUSER="${RUNUSER:=$USER}"
RUNUSER="${RUNUSER:=$SUDO_USER}"
RUNUSER="${RUNUSER:=$(id -un "$EUID" 2>/dev/null)}"
RUNUSER="${RUNUSER:=$(logname 2>/dev/null)}"

SSRV_ELF="$RUNSTATIC/ssrv"
CHISEL="$RUNSTATIC/chisel"

if [[ "$RIM_AUTORUN" == 'rim-'* ]]
    then
        case "$RIM_AUTORUN" in
            rim-shrink|rim-dinteg|rim-bootstrap);;
            *) ARG1="$RIM_AUTORUN"
               ARGS=("${RIM_AUTORUN[@]:1}" "${ARGS[@]}")
               unset RIM_AUTORUN ;;
        esac
elif [[ "$ARG1" == 'rim-'* ]]
    then unset RIM_AUTORUN
fi

[[ -n "$RIM_AUTORUN" && "$RIM_AUTORUN" != 0 ]] && \
AUTORUN0ARG=($RIM_AUTORUN)||unset RIM_AUTORUN AUTORUN0ARG

unset SSRV_RUNPID SSRV_SOCK_PATH
if [ "$RIM_RUN_IN_ONE" == 1 ]
    then
        RUNIMAGEDIR_SUM=($(sha1sum<<<"$RUNIMAGEDIR"))
        SSRV_SOCK_PATH="$RUNPIDDIR/${RUNIMAGEDIR_SUM}.sock"
        SSRV_RUNPID="$(ls -1 "$RUNTMPDIR"/*/"${RUNIMAGEDIR_SUM}.sock" 2>/dev/null|gawk -F'/' 'NR==1{print $(NF-1)}')"
        if [ -n "$SSRV_RUNPID" ]
            then
                if is_pid "$SSRV_RUNPID"
                    then SSRV_SOCK_PATH="${RUNTMPDIR}/${SSRV_RUNPID}/${RUNIMAGEDIR_SUM}.sock"
                    else rm -f "${RUNTMPDIR}/${SSRV_RUNPID}.${RUNIMAGEDIR_SUM}.sock"
                fi
        fi
        export SSRV_SOCK="unix:$SSRV_SOCK_PATH"
fi

if is_rio_running
    then
        unset RIO_SKIP_START
        RIO_ARGS=(run_attach)
        case "$ARG1" in
            rim-portfw ) RIO_ARGS+=(portfw) ;;
            *) RIO_ARGS+=(exec) ;;
        esac
        RIO_ARGS+=("$SSRV_RUNPID")
        case "$ARG1" in
            rim-portfw|rim-exec|rim-shrink|rim-bootstrap);;
            rim-dinteg)
                export RIM_DINTEG=1
                if [ "$RIM_SHARE_ICONS" == 1 ]
                    then
                        RIO_SKIP_START=1
                        RIM_SHARE_ICONS=0
                fi ;;
            rim-desktop|\
            rim-update |\
            rim-build  ) RIO_ARGS+=("$ARG1") ;;
            rim-shell) [ -n "$RIM_SHELL" ]||RIM_SHELL=sh ; RIO_ARGS+=("${RIM_SHELL[@]}") ;; # FIXME
            rim-*) error_msg "Option is not supported for a running RunImage container: $ARG1"
                   exit 1 ;;
        esac
        if [ "$RIO_SKIP_START" != 1 ]
            then rim_start "${RIO_ARGS[@]}"
        fi
    else
        case "$ARG1" in
            rim-dinteg    ) RIM_SHARE_ICONS=0 ; export RIM_DINTEG=1 ;;
            rim-pkgls  |\
            rim-binls     ) set_default_option ; RIM_QUIET_MODE=1 ; RIM_CONFIG=0
                            RIM_DINTEG=0 ;;
            rim-decfs     ) set_overfs_option crypt ;;
            rim-encfs  |\
            rim-enc-passwd) set_overfs_option crypt ; RIM_NO_CRYPTFS_MOUNT=1 ;;
            rim-version   ) set_default_option ; RIM_DINTEG=0 ;;
            rim-build     ) set_default_option ; RIM_DINTEG=0
                            if [ -d "$RIM_ROOTFS" ]
                                then
                                    RIM_TMP_HOME=0
                                    RIM_UNSHARE_HOME=0
                                    RIM_SANDBOX_HOME=0
                            fi ;;
            rim-ofsrm     ) set_default_option ; RIM_NO_CRYPTFS_MOUNT=1 ; RIM_DINTEG=0 ;;
            rim-exec      ) run_attach exec "${ARGS[@]}"; exit $? ;;
            rim-portfw    ) run_attach portfw "${ARGS[@]}"; exit $? ;;
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
                                    export FORCE_KILL_PPID=1
                            fi ;;
        esac
fi

mkdir -p "$RUNPIDDIR"
chmod go-rwx "$REUIDDIR"/{,/run}

echo "$RUNDIR" > "$RUNDIRFL"

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

if [[ -d "$RIM_ROOTFS" && "$RIMSHRINKLDSO" != 1 ]]
    then
        RIM_TMP_HOME="${RIM_TMP_HOME:=0}"
        RIM_XORG_CONF="${RIM_XORG_CONF:=0}"
        RIM_HOST_TOOLS="${RIM_HOST_TOOLS:=0}"
        RIM_SANDBOX_NET="${RIM_SANDBOX_NET:=0}"
        RIM_TMP_HOME_DL="${RIM_TMP_HOME_DL:=0}"
        RIM_UNSHARE_NSS="${RIM_UNSHARE_NSS:=1}"
        RIM_UNSHARE_HOME="${RIM_UNSHARE_HOME:=1}"
        RIM_SANDBOX_HOME="${RIM_SANDBOX_HOME:=0}"
        RIM_PORTABLE_HOME="${RIM_PORTABLE_HOME:=0}"
        RIM_UNSHARE_USERS="${RIM_UNSHARE_USERS:=1}"
        RIM_UNSHARE_HOSTS="${RIM_UNSHARE_HOSTS:=1}"
        RIM_WAIT_RPIDS_EXIT="${RIM_WAIT_RPIDS_EXIT:=0}"
        RIM_SANDBOX_HOME_DL="${RIM_SANDBOX_HOME_DL:=0}"
        RIM_UNSHARE_HOSTNAME="${RIM_UNSHARE_HOSTNAME:=1}"
        RIM_UNSHARE_LOCALTIME="${RIM_UNSHARE_LOCALTIME:=1}"
        RIM_UNSHARE_RESOLVCONF="${RIM_UNSHARE_RESOLVCONF:=1}"
        if [ -w "$RUNROOTFS" ]
            then
                lib_pathfl="$RUNROOTFS/usr/lib/lib.path"
                if [ ! -e "$lib_pathfl" ]
                    then
                        mkdir -p "$(dirname "$lib_pathfl")"
                        echo '+' > "$lib_pathfl"
                fi
                for ver in 2 1
                    do
                        if [ -f "$RUNROOTFS"/usr/lib/*-linux-gnu/ld-linux-*.so.${ver} ] && \
                            [ ! -e "$RUNROOTFS"/usr/lib/ld-linux-*.so.${ver} ]
                            then
                                (cd "$RUNROOTFS/usr/lib"
                                ln -sf *-linux-gnu/ld-linux-*.so.${ver} .)
                        fi
                done
                ld_gnu_libs_dir="$(basename "$(ls -d "$RUNROOTFS"/usr/lib/*-linux-gnu 2>/dev/null|head -1)")"
                if [ -n "$ld_gnu_libs_dir" ] && \
                    ! grep -q "+/$ld_gnu_libs_dir" "$lib_pathfl"
                    then echo "+/$ld_gnu_libs_dir" >> "$lib_pathfl"
                fi
                for ver in 2 1
                    do
                        if [ -f "$RUNROOTFS"/usr/lib64/ld-linux-*.so.${ver} ] && \
                            [ ! -e "$RUNROOTFS"/usr/lib/ld-linux-*.so.${ver} ]
                            then
                                (cd "$RUNROOTFS/usr/lib"
                                ln -sf ../lib64 .
                                ln -sf ../lib64/ld-linux-*.so.${ver} .)
                        fi
                done
                if [ -d "$RUNROOTFS/usr/lib/lib64" ] && \
                    ! grep -q '+/lib64' "$lib_pathfl"
                    then echo '+/lib64' >> "$lib_pathfl"
                fi
                if [ -f "$RUNROOTFS"/lib/ld-musl-*.so.1 ] && \
                    [ ! -e "$RUNROOTFS"/usr/lib/ld-musl-*.so.1 ]
                    then
                        (cd "$RUNROOTFS/usr/lib"
                        ln -sf ../../lib/ld-musl-*.so.1 .)
                fi
                (cd "$RUNROOTFS/usr/bin"
                for bin in $(cat "$RUNDIR/sharun/bin.list" 2>/dev/null|sed "s|^/usr/bin/||g")
                    do
                        for dir in bin sbin
                            do
                                if [[ ! -e "$bin" && -e "../../$dir/$bin" ]]
                                    then ln -sf "../../$dir/$bin" .
                                fi
                        done
                done
                if [[ ! -e 'ldconfig' && -e '../sbin/ldconfig' ]]
                    then ln -sf '../sbin/ldconfig' .
                fi)
                if [[ ! -e "$RUNROOTFS/etc/os-release" && -f "$RUNROOTFS/usr/lib/os-release" ]]
                    then (cd "$RUNROOTFS/etc" && ln -sf ../usr/lib/os-release .)
                fi
                if [ -d "$RUNROOTFS/etc/apt" ]
                    then
                        aptdisndbxfl="$RUNROOTFS/etc/apt/apt.conf.d/99-disable-sandbox"
                        if [ ! -f "$aptdisndbxfl" ]
                            then
                                try_mkdir "$(dirname "$aptdisndbxfl")"
                                cat <<EOF>"$aptdisndbxfl"
APT::Sandbox::User "root";
APT::Sandbox::Verify "0";
APT::Sandbox::Verify::IDs "0";
APT::Sandbox::Verify::Groups "0";
APT::Sandbox::Verify::Regain "0";
EOF
                        fi
                fi
                pacman_conffl="$RUNROOTFS/etc/pacman.conf"
                if [ -f "$pacman_conffl" ]
                    then sed -i 's|^DownloadUser|#DownloadUser|;s|^SigLevel.*|SigLevel = Never|;s|^#Color|Color|;s|^#ParallelDownloads|ParallelDownloads|' "$pacman_conffl"
                fi
                BIND_FILES=(
                    etc/machine-id var/lib/dbus/machine-id
                    etc/resolv.conf etc/localtime etc/hosts
                    etc/hostname etc/X11/xorg.conf var/log/wtmp
                    var/log/lastlog home/runimage/.Xauthority
                    .type etc/nsswitch.conf etc/passwd etc/group
                )
                for bind_file in "${BIND_FILES[@]}"
                    do
                        bind_file="$RUNROOTFS/$bind_file"
                        if [ -L "$bind_file" ]
                            then rm -f "$bind_file"
                        fi
                        if [ ! -e "$bind_file" ]
                            then
                                try_mkdir "$(dirname "$bind_file")"
                                touch "$bind_file"
                        fi
                done
                BIND_DIRS=(
                    home/runimage/.cache home/runimage/.config
                    usr/lib/modules lib/modules var/home
                    var/mnt var/roothome var/host/bin boot
                    dev root proc sys run tmp media
                    mnt /proc var/tmp var/log usr/share/themes
                    usr/share/fonts usr/share/icons
                )
                for bind_dir in "${BIND_DIRS[@]}"
                    do try_mkdir "$RUNROOTFS/$bind_dir"
                done
                rim_rootfs_verfl="$RUNROOTFS/.version"
                if [ ! -e "$rim_rootfs_verfl" ]
                    then echo "$RUNIMAGE_VERSION" > "$rim_rootfs_verfl"
                fi
        fi
fi

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
if [ "$RIM_UNSHARE_LOCALTIME" == 1 ]
    then warn_msg "Host /etc/localtime is unshared!"
    else LOCALTIME_BIND+=("--ro-bind-try" "/etc/localtime" "/etc/localtime")
fi

TINI_PIDFL="$RUNPIDDIR/tini.pid"
(while is_pid "$RUNPID" && [ ! -f "$TINI_PIDFL" ]
    do
        TINI_PID="$(ps -opid=,cmd= -p $(get_child_pids "$RUNPID") 2>/dev/null|\
                    grep -E '^( *)?[0-9]* /var/RunDir/static/tini'|gawk '{print$1}')"
        [ -n "$TINI_PID" ] && echo "$TINI_PID" > "$TINI_PIDFL"
        sleep 0.1 2>/dev/null
done) &

if [[ ! -n "$DBUS_SESSION_BUS_ADDRESS" && "$RIM_UNSHARE_DBUS" != 1 ]]
    then
        if [ -S "$XDG_RUNTIME_DIR/bus" ]
            then export DBUS_SESSION_BUS_ADDRESS="unix:path=$XDG_RUNTIME_DIR/bus"
        elif get_dbus_session_bus_address &>/dev/null
            then export $(get_dbus_session_bus_address)
        fi
fi

[ "$RIM_SYS_TOOLS" == 1 ] && \
    RIM_SYS_MKSQFS=1 RIM_SYS_GOCRYPTFS=1 \
    RIM_SYS_SQFUSE=1 RIM_SYS_BWRAP=1 \
    RIM_SYS_UNIONFS=1 RIM_SYS_SLIRP=1 \

if [ "$RIM_SYS_MKSQFS" == 1 ] && is_sys_exe mksquashfs
    then
        info_msg "The system mksquashfs is used!"
        MKSQFS="$(which_sys_exe mksquashfs)"
    else
        MKSQFS="$RUNSTATIC/mksquashfs"
fi
if [ "$RIM_SYS_SLIRP" == 1 ] && is_sys_exe slirp4netns
    then
        info_msg "The system slirp4netns is used!"
        SLIRP="$(which_sys_exe slirp4netns)"
    else
        SLIRP="$RUNSTATIC/slirp4netns"
fi
if [ "$RIM_SYS_SQFUSE" == 1 ] && is_sys_exe squashfuse
    then
        info_msg "The system squashfuse is used!"
        SQFUSE="$(which_sys_exe squashfuse)"
    else
        SQFUSE="$RUNSTATIC/squashfuse"
fi
if [ "$RIM_SYS_UNIONFS" == 1 ] && is_sys_exe unionfs
    then
        info_msg "The system unionfs is used!"
        UNIONFS="$(which_sys_exe unionfs)"
    else
        UNIONFS="$RUNSTATIC/unionfs"
fi
if [ "$RIM_SYS_GOCRYPTFS" == 1 ] && is_sys_exe gocryptfs
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
                RIM_SYS_BWRAP=1
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

if [ "$RIM_SYS_BWRAP" == 1 ] && is_sys_exe bwrap
    then
        info_msg "The system Bubblewrap is used!"
        BWRAP="$(which_sys_exe bwrap)"
    else
        BWRAP="$RUNSTATIC/bwrap"
fi
unset SUID_BWRAP
if [[ "$RIM_SYS_BWRAP" == 1 && "$EUID" != 0 && \
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
        BWRAP_CAP=("--cap-add" "ALL")
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
        [[ "$(findmnt -n -o FSTYPE -T "$OVERFS_DIR" 2>/dev/null)" =~ (aufs|overlay) ]] && \
           export RIM_NO_BWRAP_OVERLAY=1
        if [ -d "$RIM_ROOTFS" ]
            then
                warn_msg "UnionFS and CryptFS mode are not supported for custom RunImage rootfs!"
                RIM_OVERFS_MODE=0
                RIM_NO_CRYPTFS_MOUNT=1
                if [ "$RIM_NO_BWRAP_OVERLAY" != 1 ]
                    then
                        try_mkdir "$OVERFS_DIR/workdir"
                        try_mkdir "$OVERFS_DIR/layers/rootfs"
                        BOVERLAY_SRC="$RUNROOTFS"
                    else
                        warn_msg "Bubblewrap OverlayFS is disabled!"
                fi
            else
                mkdir -p "$OVERFS_DIR"/{layers,mnt}
                UNIONFS_ARGS=(
                    -f -o max_files=$(ulimit -n -H),nodev,hide_meta_files,cow,nodev
                    -o uid=$EUID,gid=${EGID}$([ "$EUID" != 0 ] && echo ,relaxed_permissions)
                    -o dirs="$OVERFS_DIR/layers"=RW:"$RUNDIR"=RO
                )
                if ! is_cryptfs && [ "$RIM_NO_BWRAP_OVERLAY" != 1 ]
                    then
                        try_mkdir "$OVERFS_DIR/workdir"
                        try_mkdir "$OVERFS_DIR/layers/rootfs"
                        BOVERLAY_SRC="$RUNROOTFS"
                    else
                        warn_msg "Bubblewrap OverlayFS is disabled!"
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
                        error_msg "Failed to mount RunImage in UnionFS overlay mode!"
                        cleanup force
                        exit 1
                fi
                export RUNROOTFS="$OVERFS_MNT/rootfs"
                CRYPTFS_MNT="$OVERFS_DIR/rootfs"
                CRYPTFS_DIR="$OVERFS_MNT/cryptfs"
                export_rootfs_info
        fi
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

[ -d "$RIM_ROOTFS" ] && RUNDIR_BIND+=("--bind-try" "$RUNROOTFS" "/var/RunDir/rootfs")

CRYPTFS_ARGS=("$GOCRYPTFS" "$CRYPTFS_DIR" "$CRYPTFS_MNT" '--nosyslog')
if [ ! -n "$RIM_CRYPTFS_PASSFILE" ]
    then
        if [ -f "$RUNIMAGEDIR/passfile" ]
            then RIM_CRYPTFS_PASSFILE="$RUNIMAGEDIR/passfile"
        elif [ -f "$RUNDIR/passfile" ]
            then RIM_CRYPTFS_PASSFILE="$RUNDIR/passfile"
        fi
fi
if [ -f "$RIM_CRYPTFS_PASSFILE" ]
    then
        info_msg "GoCryptFS passfile: '$RIM_CRYPTFS_PASSFILE'"
        CRYPTFS_ARGS+=("--passfile" "$RIM_CRYPTFS_PASSFILE")
    else unset RIM_CRYPTFS_PASSFILE
fi

unset KEEP_CRYPTFS
if is_cryptfs && [ "$RIM_NO_CRYPTFS_MOUNT" != 1 ]
    then
        export RIM_CMPRS_LVL=1 RIM_CMPRS_ALGO=zstd
        try_mkdir "$CRYPTFS_MNT"
        if [ ! -n "$(ls -A "$CRYPTFS_MNT" 2>/dev/null)" ]
            then
                info_msg "Mounting RunImage rootfs in GoCryptFS mode..."
                if [ -f "$RIM_CRYPTFS_PASSFILE" ]
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
        RUNDIR_BIND+=("--bind-try" "$RUNROOTFS" "/var/RunDir/rootfs")
        export CRYPTFS_DIR
        export CRYPTFS_MNT
        export_rootfs_info
fi

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
/var/RunDir/static:/var/RunDir/utils:/var/RunDir/sharun/bin"
[ -n "$LD_LIBRARY_PATH" ] && \
    add_lib_pth "$LD_LIBRARY_PATH"

check_autorun

SETENV_ARGS=()
if [ ! -n "$RIM_SHELL" ]
    then
        if [ -x "$RUNROOTFS/usr/bin/fish" ]
            then RIM_SHELL='/usr/bin/fish'
        elif [ -x "$RUNROOTFS/bin/zsh" ]
            then RIM_SHELL='/bin/zsh'
        elif [ -x "$RUNROOTFS/bin/bash" ]
            then RIM_SHELL=('/bin/bash' '--rcfile' '/etc/bash.bashrc')
        elif [ -x "$RUNROOTFS/usr/bin/dash" ]
            then RIM_SHELL='/usr/bin/dash'
        elif [ -x "$RUNROOTFS/bin/ash" ]
            then RIM_SHELL='/bin/ash'
        else RIM_SHELL='/bin/sh'
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
        [ -d "$RIM_SANDBOX_HOME_DIR" ] && RIM_SANDBOX_HOME=1
    else unset RIM_SANDBOX_HOME_DIR
fi

unset HOME_BIND SET_HOME_DIR NEW_HOME
if [ "$RIM_TMP_HOME" != 0 ] && [[ "$RIM_TMP_HOME" == 1 || "$RIM_TMP_HOME_DL" == 1 ]]
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
        RIM_TMP_HOME=1
elif [ "$RIM_UNSHARE_HOME" != 0 ] && [[ "$RIM_UNSHARE_HOME" == 1 || "$RIM_UNSHARE_HOME_DL" == 1 ]]
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
                    ! -L "$RUNROOTFS/$UNSHARED_HOME" && "$RIM_NO_CRYPTFS_MOUNT" != 1 ]]
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
        RIM_UNSHARE_HOME=1
elif [ "$RIM_SANDBOX_HOME" != 0 ] && [[ "$RIM_SANDBOX_HOME" == 1 || "$RIM_SANDBOX_HOME_DL" == 1 || -d "$RIM_SANDBOX_HOME_DIR" ]]
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
        RIM_SANDBOX_HOME=1
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
            then warn_msg "Host /etc/hosts is unshared!"
            else NETWORK_BIND+=("--ro-bind-try" "/etc/hosts" "/etc/hosts")
        fi
        if [ "$RIM_UNSHARE_RESOLVCONF" == 1 ]
            then warn_msg "Host /etc/resolv.conf is unshared!"
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
                    then RIM_XORG_CONF="$RUNIMAGEDIR/xorg.conf"
                elif [ -f "$RUNDIR/xorg.conf" ]
                    then RIM_XORG_CONF="$RUNDIR/xorg.conf"
                fi
        fi
        if [ -f "$RIM_XORG_CONF" ]
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
        if ! grep -wo "^$RUNUSER:x:$EUID:0" "$RUNROOTFS/etc/passwd" &>/dev/null||\
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

ICONS_BIND=()
if [[ "$RIM_SHARE_ICONS" == 1 && -d '/usr/share/icons' ]]
    then
        info_msg "Host /usr/share/icons is shared!"
        ICONS_BIND+=('--ro-bind-try' '/usr/share/icons' '/usr/share/icons')
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

if [ "$RIM_DINTEG" == 1 ] && \
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
    rim-binls     ) bin_list ;;
    rim-version   ) print_version ;;
    rim-ofsls     ) overlayfs_list ;;
    rim-update    ) run_update "${ARGS[@]}" ;;
    rim-ofsrm     ) overlayfs_rm "${ARGS[@]}" ;;
    rim-desktop   ) bwrun rim-desktop "${ARGS[@]}" ;;
    rim-shell     ) bwrun "${RIM_SHELL[@]}" "${ARGS[@]}" ;;
    rim-psmon     ) bwrun rim-psmon "${ARGS[@]}" ;;
    rim-build     ) run_build "${ARGS[@]}" ;;
    *) rim_start bwrun ;;
esac
EXIT_STAT="$?"

if [ "$RIM_WAIT_RPIDS_EXIT" == 1 ]
    then
        trap cleanup INT
        find_processes() {
            processes="$(ps -ocmd= -p $(get_child_pids "$RUNPID") 2>/dev/null|grep -Ev "$IGNPS")"
        }
        IGNPS="$RUNPIDDIR|$RUNDIR|/var/RunDir|$RUNIMAGEDIR"
        [ -n "$SSRV_PID" ] && IGNPS+="|slirp4netns.*$SSRV_PID"
        find_processes
        while is_pid "$RUNPID" && \
            [ -n "$processes" ]
            do
                sleep 1
                find_processes
        done
        [ -f "$BWINFFL" ] && \
            rm -f "$BWINFFL" 2>/dev/null
        kill $SSRV_PID 2>/dev/null
        [ -e "$SSRV_SOCK_PATH" ] && \
            rm -f "$SSRV_SOCK_PATH" 2>/dev/null
        sleep 0.1
fi

exit $EXIT_STAT

##############################################################################
