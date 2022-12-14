# RunImage

## **Portable single-file unprivileged Linux container in user namespaces.**

![image](https://user-images.githubusercontent.com/57139938/202873005-a7b4fcf3-aff3-4498-90b4-3b19ef8bd146.png)

RunImage is designed to be completely static and portable to run on almost any Linux. It is based on a specially configured [Arch Linux rootfs](https://github.com/VHSgunzo/runimage-rootfs/releases). The technology of single-file containerization is based on a modified static AppImage [runtime](https://github.com/VHSgunzo/runimage-runtime-static), squashfs image with lz4 compression method for better work speed, statically compiled [binaries](https://github.com/VHSgunzo/runimage-static/releases) for the operation of the container [Run script](https://github.com/VHSgunzo/runimage/blob/main/Run), and containerization itself is carried out by [statically compiled](https://github.com/VHSgunzo/bubblewrap-static/releases) [Bubblewrap](https://github.com/containers/bubblewrap).

In addition, RunImage has the ability to isolate itself from the main system, use separate portable home directories and configuration files for each executable file being run, and run separate X11 servers, including running multiple Xorg servers on TTY. XFCE is used as DE.

You can use it to develop and run any applications and games, including applications and games for Windows, launch games from retro platforms using popular emulators, work with the office, with remote desktops, multimedia, browsers, messengers, and even run virtual machines with QEMU/KVM and Virt-Manager, USB and block device forwarding in VM also works.

Also inside the container, you can use various means of proxification, such as proxychains, tor and others and run VNC and SSH servers.

The full list of installed packages can be found in the [**releases**](https://github.com/VHSgunzo/runimage/releases) file `pkg_list-{release_type}.txt`

## Features:

* A Portable single executable file with an idea - downloaded and launched. Nothing needs to be installed in the system.
* Works on most Linux distributions, including even very old ones or without glibc or systemd and in live boot mode.
* OverlayFS mode (It looks like the usual means of containerization like docker) (See [Usage](https://github.com/VHSgunzo/runimage#usage-from-runimage-help)).
* Read-Write mount in OverlayFS mode.
* Running and working without root rights, including package management in unpacked form or in OverlayFS mode.
* The ability to work in a packed and unpacked form. Unpacked, you will get a higher work speed, but about ~2-3 more occupied disk space
* The ability to run both 32-bit and 64-bit executable files.
* Based on Arch Linux, contains the latest software and [AUR](https://aur.archlinux.org) support.
* Access to [BlackArch](https://github.com/BlackArch/blackarch) repositories.
* The ability to use both separate home directories for each executable file, and completely seamless use of the system home directory.
* The ability to use separate configuration files for each launched executable file (see [config](https://github.com/VHSgunzo/runimage/tree/main/config)).
* There is no performance drawdown. All applications and executable files run at the same speed as in the system.
* Supports filesystem and X11 sandboxing and network isolation.
* Temporary home directory in RAM (can be used as a real private mode for browsers and applications)
* The ability to launching a full DE in windowed mode and on TTY.
* Works with any versions of nvidia proprietary drivers.
* Works in Wayland session
* Usability and comprehensibility.

## Requirements:
* Supported architectures (should work on any Linux kernel architecture. However, it is currently only built for x86_64)
* Minimum recommended Linux kernel version 4.18+ (tested on Centos 7 with 3.10 and on Ubuntu 12.04 with 3.11 using SUID Bubblewrap and it's works, but 5.0+ with [user namespaces](https://lwn.net/Articles/531114) support is recommended)
* FUSE (but not necessarily, because it is possible to work in unpacked form without FUSE mounting)

## To get started:

1. Download latest release from the [**releases**](https://github.com/VHSgunzo/runimage/releases) page.
2. Make it executable before run.
```
chmod +x runimage*
```

## Usage (from RunImage help):
```
?????????[user@host]???[~]
???????????? $ runimage {bubblewrap args} {executable} {executable args}

    --run-help   |--rH                   Show this usage info
    --run-bwhelp |--rBwh                 Show Bubblewrap usage info
    --run-version|--rV                   Show runimage, rootfs, static, runtime version
    --run-pkglist|--rP                   Show packages installed in runimage
    --run-binlist|--rBin                 Show /usr/bin in runimage
    --run-shell  |--rS {args}            Run runimage shell or execute a command in runimage shell
    --run-desktop|--rD                   Launch runimage desktop
    --overfs-list|--oL                   Show the list of runimage OverlayFS
    --overfs-rm  |--oR {id id ...|all}   Remove OverlayFS
    --run-build  |--rB {build args}      Build new runimage container
    --run-update |--rU {build args}      Update packages and rebuild runimage

Only for not extracted (RunImage runtime options):
    --runtime-extract {pattern}          Extract content from embedded filesystem image
    --runtime-extract-and-run {args}     Run runimage afer extraction without using FUSE
    --runtime-help                       Show runimage runtime help (Shown in this help)
    --runtime-mount                      Mount embedded filesystem image and print
    --runtime-offset                     Print byte offset to start of embedded
    --runtime-portable-home              Create a portable home folder to use as $HOME
    --runtime-portable-config            Create a portable config folder to use as $XDG_CONFIG_HOME
    --runtime-version                    Print version of runimage runtime

Environment variables to configure:
    NO_INET=1                            Disables network access
    TMP_HOME=1                           Creates tmpfs /home/$USER and /root in RAM and uses it as $HOME
    TMP_HOME_DL=1                        As above, but with binding $HOME/Downloads directory
    PORTABLE_HOME=1                      Creates a portable home folder and uses it as $HOME
    PORTABLE_CONFIG=1                    Creates a portable config folder and uses it as $XDG_CONFIG_HOME
    NO_CLEANUP=1                         Disables unmounting and cleanup mountpoints
    FORCE_CLEANUP=1                      Kills all runimage background processes when exiting
    NO_KILL_FUSE=1                       Disables killing squashfuse processes when exiting
    NO_NVIDIA_CHECK=1                    Disables checking the nvidia driver version
    NO_DOUBLE_MOUNT=1                    Disables the second mount that fixes MangoHud and VkBasalt bug
    OVERFS_MODE=1                        Enables OverlayFS mode
    KEEP_OVERFS=1                        Enables OverlayFS mode with saving after closing runimage
    OVERFS_ID=ID                         Specifies the OverlayFS ID
    KEEP_OLD_BUILD=1                     Creates a backup of the old RunImage when building a new one
    BUILD_WITH_EXTENSION=1               Adds an extension when building (compression method and rootfs type)
    RUN_SHELL="shell"                    Selects $SHELL in runimage
    NO_CAP=1                             Disables Bubblewrap capabilities (Default: ALL, drop CAP_SYS_NICE)
                                            you can also use /usr/bin/nocap in runimage
    AUTORUN="{executable} {args}"        Run runimage with autorun options for /usr/bin executables
    ALLOW_ROOT=1                         Allows to run runimage under root user
    QUIET_MODE=1                         Disables all non-error runimage messages
    NO_NOTIFY=1                          Disables all notification
    UNSHARE_PIDS=1                       Hides all system processes in runimage
    RUNTIME_EXTRACT_AND_RUN=1            Run runimage afer extraction without using FUSE
    TMPDIR="/path/{TMPDIR}"              Used for extract and run options
    RUNIMAGE_CONFIG="/path/{config}"     runimage ??onfiguration file (0 to disable)
    XORG_CONF="/path/xorg.conf"          Binds xorg.conf to /etc/X11/xorg.conf in runimage (0 to disable)
                                            (Default: /etc/X11/xorg.conf bind from the system)
    XEPHYR_SIZE="HEIGHTxWIDTH"           Sets runimage desktop resolution (Default: 1600x900)
    XEPHYR_DISPLAY=":9999"               Sets runimage desktop $DISPLAY (Default: :1337)
    XEPHYR_FULLSCREEN=1                  Starts runimage desktop in full screen mode
    UNSHARE_CLIPBOARD=1                  Disables clipboard synchronization for runimage desktop

    SYS_BWRAP=1                          Using system bwrap
    SYS_SQFUSE=1                         Using system squashfuse
    SYS_ARIA2C=1                         Using system aria2c
    SYS_UNSQFS=1                         Using system unsquashfs
    SYS_MKSQFS=1                         Using system mksquashfs
    SYS_FOVERFS=1                        Using system fuse-overlayfs
    SYS_TOOLS=1                          Using all these binaries from the system
                                         If they are not found in the system - auto return to the built-in

Other environment variables:
    RunImage path (for packed):
        RUNIMAGE=""
    Null argument (for packed):
        ARGV0=""
    Squashfs offset (for packed):
        RUNOFFSET=""
    Run script directory:
        RUNDIR=""
    RootFS directory:
        RUNROOTFS=""
    Static binaries directory:
        RUNSTATIC=""
    RunImage or RunDir directory:
        RUNIMAGEDIR=""
    Cache directory:
        RUNCACHEDIR=""
    RunImage name or link name or executable name:
        RUNSRCNAME=""
    RunImage version:
        RUNIMAGE_VERSION=""
    RootFS version:
        RUNROOTFS_VERSION=""
    Static version:
        RUNSTATIC_VERSION=""
    RunImage runtime version:
        RUNRUNTIME_VERSION=""
    Directory for all OverlayFS:
        RUNOVERFSDIR=""
    OverlayFS ID directory:
        OVERFS_DIR=""
    OverlayFS ID mount directory:
        OVERFS_MNT=""
    RunImage runtime:
        RUNRUNTIME=""
    Rootfs type:
        RUNROOTFSTYPE=""
    squashfuse and fuse-overlayfs PIDs:
        FUSE_PIDS=""
    The name of the user who runs runimage:
        RUNUSER=""
    mksquashfs:
        MKSQFS=""
    unsquashfs:
        UNSQFS=""
    aria2c:
        ARIA2C=""
    fuse-overlayfs:
        FOVERFS=""
    squashfuse:
        SQFUSE=""
    bwrap:
        BWRAP=""

Custom scripts and aliases:
    /bin/cip                          ??heck public ip
    /bin/dbus-flmgr                   Launch the system file manager via dbus
    /bin/nocap                        Disables container capabilities
    /bin/sudo                         Fake sudo (fakechroot fakeroot)
    /bin/pac                          sudo pacman (fake sudo)
    /bin/packey                       sudo pacman-key (fake sudo)
    /bin/panelipmon                   Shows information about an active network connection
    /bin/runbuild                     Starts the runimage build
    /bin/rundesktop                   Starts the desktop mode
    /bin/{xclipsync,xclipfrom}        For clipboard synchronization in desktop mode
    /bin/webm2gif                     Convert webm to gif
    /bin/transfer                     Upload file to https://transfer.sh

    ls='ls --color=auto'
    dir='dir --color=auto'
    grep='grep --color=auto'
    vdir='vdir --color=auto'
    fgrep='fgrep --color=auto'
    egrep='egrep --color=auto'
    rm='rm -i'
    cp='cp -i'
    mv='mv -i'
    ll='ls -lh'
    la='ls -lha'
    l='ls -CF'
    em='emacs -nw'
    _='sudo'
    _i='sudo -i'
    please='sudo'
    fucking='sudo'
    cip='curl -s ifconfig.io 2>/dev/null'
    dd='dd status=progress'
    pac='sudo pacman'
    pacman='sudo pacman'
    pacman-key='sudo pacman-key'
    packey='sudo pacman-key'

Additional information:
    You can create a symlink/hardlink to runimage or rename runimage and give it the name
        of some executable file from /usr/bin in runimage, this will allow you to run
        runimage in autorun mode for this executable file.
    The same principle applies to the AUTORUN variable:
        ??????[user@host]???[~]
        ???????????? $ AUTORUN="ls -la" runimage {autorun executable args}
    Here runimage will become something like an alias for 'ls' in runimage
        with the '-la' argument. You can also use AUTORUN as an array for complex commands in the config.
        AUTORUN=("ls" "-la" "/path/to something")
    This will also work in extracted form for the Run script.

    When using the PORTABLE_HOME and PORTABLE_CONFIG variables, runimage will create or
        search for these directories next to itself. The same behavior will occur when
        adding a runimage or Run script or renamed or symlink/hardlink to them in the PATH
        it can be used both extracted and compressed and for all executable files being run:
            '$RUNIMAGEDIR/Run.home'
            '$RUNIMAGEDIR/Run.config'
        if a symlink/hardlink to runimage is used:
            '$RUNIMAGEDIR/{symlink/hardlink_name}.home'
            '$RUNIMAGEDIR/{symlink/hardlink_name}.config'
        or with runimage/Run name:
            '$RUNIMAGEDIR/{runimage/Run_name}.home'
            '$RUNIMAGEDIR/{runimage/Run_name}.config'
        It can also be with the name of the executable file from AUTORUN environment variables,
            or with the same name as the executable being run.

    RunImage uses fakeroot and fakechroot, which allows you to use root commands, including in
        unpacked form, to update the rootfs or install/remove packages.
        sudo and pkexec have also been replaced with fake ones. (see /usr/bin/sudo /usr/bin/pkexec)

    RunImage configuration file:
        Special BASH-syntax file with the .rcfg extension, which describes additional
            instructions and environment variables for running runimage.
        Configuration file can be located next to runimage:
            '$RUNIMAGEDIR/{runimage/Run_name}.rcfg'
        it can be used both extracted and compressed and for all executable files being run:
            '$RUNIMAGEDIR/Run.rcfg'
        if a symlink/hardlink to runimage is used:
            '$RUNIMAGEDIR/{symlink/hardlink_name}.rcfg'
        or in $RUNIMAGEDIR/config directory:
            '$RUNIMAGEDIR/config/Run.rcfg'
            '$RUNIMAGEDIR/config/{runimage/Run_name}.rcfg'
            '$RUNIMAGEDIR/config/{symlink/hardlink_name}.rcfg'
        It can also be with the name of the executable file from AUTORUN environment variables,
            or with the same name as the executable being run.
        In $RUNDIR/config there are default configs in RunImage, they are run in priority,
            then external configs are run if they are found.

    RunImage desktop:
        Ability to run RunImage in desktop mode. Default DE: XFCE (see /usr/bin/rundesktop)
        If the launch is carried out from an already running desktop, then Xephyr will start
            in windowed mode (see XEPHYR_* environment variables)
            Use CTRL+SHIFT to grab the keyboard and mouse.
        It is also possible to run on TTY with Xorg (see XORG_CONF environment variables)
            To do this, just log in to TTY and run RunImage desktop.
        Important! The launch on the TTY should be carried out only under the user under whom the
            login to the TTY was carried out.

    RunImage OverlayFS:
        Allows you to create additional separate layers to modify the container file system without
            changing the original container file system. Works packed and unpacked. Also, in packed form,
            it allows you to mount the container in RW mode.
        It also allows you to attach to the same OverlayFS when you specify its ID:
        ??????[user@host]???[~]
        ???????????? $ OVERFS_ID=1337 runimage {args}
            If OverlayFS with such ID does not exist, it will be created.
        To save OverlayFS after closing the container, use KEEP_OVERFS:
        ??????[user@host]???[~]
        ???????????? $ KEEP_OVERFS=1 runimage {args}
        To run a one-time OverlayFS, use OVERFS_MODE:
        ??????[user@host]???[~]
        ???????????? $ OVERFS_MODE=1 runimage {args}

    RunImage build:
        Allows you to create your own runimage containers.
        This works both externally by passing build args:
        ??????[user@host]???[~]
        ???????????? $ runimage --run-build {build args}
        And it also works inside the running instance (see /bin/runbuild):
        ??????[user@host]???[~] - in runimage
        ???????????? $ runbuild {build args}
        Optionally, you can specify the following build arguments:
            {/path/new_runimage_name} {-zstd|-xz} {zstd compression level 1-19}
        By default, runimage is created in the current directory with a standard name and
            with lz4 compression. If a new RunImage is successfully build, the old one is deleted.
            (see KEEP_OLD_BUILD and BUILD_WITH_EXTENSION)

        RunImage update:
            Allows you to update packages and rebuild RunImage. In unpacked form, automatic build will
                not be performed. When running an update, you can also pass arguments for a new build.
                (see RunImage build)
            ??????[user@host]???[~]
            ???????????? $ runimage --run-update {build args}
            By default, update and rebuild is performed in '$RUNIMAGEDIR'

    For Nvidia users with a proprietary driver:
        If the nvidia driver version does not match in runimage and in the host, runimage
            will make an image with the nvidia driver of the required version (requires internet)
            or will download a ready-made image from the github repository and further used as
            an additional module to runimage.
        You can download a ready-made driver image from the releases or build driver image manually:
            https://github.com/VHSgunzo/runimage-nvidia-drivers
        In runimage, a fake version of the nvidia driver is installed by default to reduce the size:
            https://github.com/VHSgunzo/runimage-fake-nvidia-utils
        But you can also install the usual nvidia driver of your version in runimage.
        Checking the nvidia driver version can be disabled using NO_NVIDIA_CHECK variable.
        The nvidia driver image can be located next to runimage:
                '$RUNIMAGEDIR/{nvidia_version}.nv.drv'
            or in $RUNIMAGEDIR/nvidia-drivers (Default):
                '$RUNIMAGEDIR/nvidia-drivers/{nvidia_version}.nv.drv'
            or the driver can be extracted as the directory
                '$RUNIMAGEDIR/nvidia-drivers/{nvidia_version}'
            also, the driver can be in RunImage in a packed or unpacked form:
                '$RUNDIR/nvidia-drivers/{nvidia_version}.nv.drv'   -  image
                '$RUNDIR/nvidia-drivers/{nvidia_version}'          -  directory

Recommendations:
    If the kernel does not support user namespaces, you need to install
        SUID Bubblewrap into the system, or install a kernel with user namespaces support.
        If SUID Bubblewrap is found in the system, it will be used automatically.
    If you use SUID Bubblewrap, then you will encounter some limitations, such as the inability to use
        FUSE in RunImage, without running it under the root user, because the capabilities are
        disabled, and so on. So it would be better for you to install kernel with
        user namespaces support.
    I recommend installing the XanMod kernel (https://xanmod.org), because I noticed that the speed
        of runimage in compressed form on this kernel is much higher due to more correct caching settings
        and special patches.
```

## Build/Rebuild your own runimage in manual mode:
* [Download](https://github.com/VHSgunzo/runimage/releases) base version of the runimage (it will be called `runimage.base`)
* Make it executable:
```
chmod +x runimage.base
```
* Run it in OverlayFS mode (If you are using a proprietary nvidia driver, then I recommend disabling the driver check function by NO_NVIDIA_CHECK=1 for proper build/rebuild in manual mode. You do not need to do this in automatic mode):
```
OVERFS_MODE=1 ./runimage.base bash
echo $OVERFS_MNT
echo $OVERFS_ID
```
* Install or remove the necessary packages, change $OVERFS_MNT/rootfs, etc. You can change $OVERFS_MNT/rootfs in the standard ways for you. But do not close the container until the moment of build.
* After all the manipulations with rootfs, create a new runimage using this command in the container (See [Usage](https://github.com/VHSgunzo/runimage#usage-from-runimage-help)):
```
runbuild
```
* Or from another terminal tab (See [Usage](https://github.com/VHSgunzo/runimage#usage-from-runimage-help)):
```
OVERFS_ID=$OVERFS_ID ./runimage.base --run-build
```
* After the build is completed, you can close the container:
```
exit
# or CTRL-D
```

## RunImage tested and works on:

* Adelie Linux
* AlmaLinux
* Alpine
* Alt Workstation
* Antergos
* antiX
* Arch Linux
* ArcoLinux
* Artix Linux
* Astra Linux
* Batocera
* Bodhi Linux
* CachyOS
* CentOS
* ChromeOS Flex
* Clear Linux
* Debian
* Deepin
* ElementaryOS
* EndeavourOS
* EuroLinux
* Fedora Silverblue
* Fedora Workstation
* Garuda Linux
* Gentoo
* GoboLinux
* Green Linux
* Grml Linux
* Kali Linux
* KDE neon
* Kodachi
* Kubuntu
* Linux Lite
* Linux Mint
* Lubuntu
* Mageia
* Manjaro
* MX Linux
* Nitrux nxOS
* NixOS
* Nobara
* openSUSE
* Oracle Linux
* Parrot
* PCLinuxOS
* PeppermintOS (Devuan)
* Pop!_OS
* Porteus
* Puppy Linux
* Qubes
* Red OS
* Rocky Linux
* ROSA
* Simply/ALT Linux
* Slackware
* Slax Linux
* Solus
* Sparky Linux
* SteamOS (HoloISO)
* Tails
* Ubuntu
* Ubuntu MATE
* Venom Linux
* Void
* Whonix
* Windowsfx (Linuxfx)
* Windows Subsystem for Linux (WSL 2 on Win 11)
* Xubuntu
* Zorin OS

## Troubleshooting and problem solving

* Possible tearing on nvidia in RunImage desktop mode ([solution](https://wiki.archlinux.org/title/NVIDIA/Troubleshooting#Avoid_screen_tearing))
* To start the SSH server, SUID Bubblewrap or run as root is required
```
    ssh-keygen -q -N "" -t rsa -b 4096 -f ~/.ssh/ssh_host_rsa_key && \
    ssh-keygen -q -N "" -t ed25519 -b 521 -f ~/.ssh/ssh_host_ed25519_key && \
    ssh-keygen -q -N "" -t ecdsa -b 521 -f ~/.ssh/ssh_host_ecdsa_key
    echo 'ssh-rsa AAAAB3NzaC1yc2EA PUB-KEY' >> ~/.ssh/authorized_keys
    /usr/sbin/sshd
```
* When unpacked, the container is not completely static, if necessary, you need to manually add the path to the $RUNDIR/static directory to the PATH
```
    export PATH="$PATH:$RUNDIR/static"
```
* In RunImage used the [patched glibc](https://github.com/DissCent/glibc-eac-rc) to work EAC anti-cheat
* If SELinux is enabled in the system, then there may be problems with the launch and operation of Wine ([solution](https://www.tecmint.com/disable-selinux-in-centos-rhel-fedora))
* To start nested bubblewrap containerization, you need to disable capabilities (see NO_CAP env var or use [nocap](https://github.com/VHSgunzo/runimage/blob/main/rootfs/bin/nocap))
```
    NO_CAP=1 runimage {args}
    # or nocap in runimage
    nocap bwrap {args}
    nocap steam {args}
    ...
```
* When using TMP_HOME* you may run out of RAM, be careful with this.
* It is also advisable to use TMPDIR when using --runtime-extract-and-run or RUNTIME_EXTRACT_AND_RUN, because by default, unpacking before starting will be carried out in /tmp, which may also lead to the end of RAM
* With UNSHARE_PIDS, RunImage desktop does not start on TTY, freezes the entire system, (I haven't figured out what the problem is yet). Don't run RunImage desktop with UNSHARE_PIDS on TTY.
* Xephyr does not support GL acceleration and Vulkan has performance issues (But this is not related to RunImage)
* If you have problems with sound when running RunImage desktop on TTY, just restart pulseaudio.
```
    killall pulseaudio && pulseaudio -D
```
* If you disable bubblewrap capabilities using NO_CAP, you will not be able to use FUSE inside the container.

## Main used projects

* [archlinux](https://archlinux.org)
* [bubblewrap-static](https://github.com/VHSgunzo/bubblewrap-static)
* [chaotic-aur](https://aur.chaotic.cx)
* [blackarch](https://github.com/BlackArch/blackarch)
* [runimage-fake-nvidia-utils](https://github.com/VHSgunzo/runimage-fake-nvidia-utils)
* [runimage-nvidia-drivers](https://github.com/VHSgunzo/runimage-nvidia-drivers)
* [runimage-rootfs](https://github.com/VHSgunzo/runimage-rootfs)
* [runimage-runtime-static](https://github.com/VHSgunzo/runimage-runtime-static)
* [runimage-static](https://github.com/VHSgunzo/runimage-static)
* [bash-static](https://github.com/robxu9/bash-static)
* [coreutils-static](https://github.com/VHSgunzo/coreutils-static)
* [findutils-static](https://github.com/VHSgunzo/findutils-static)
* [gawk-static](https://github.com/VHSgunzo/gawk-static)
* [grep-static](https://github.com/VHSgunzo/grep-static)
* [gzip-static](https://github.com/VHSgunzo/gzip-static)
* [kmod-static](https://github.com/VHSgunzo/kmod-static)
* [notify-send-static](https://github.com/VHSgunzo/notify-send-static)
* [procps-static](https://github.com/VHSgunzo/procps-static)
* [sed-static](https://github.com/VHSgunzo/sed-static)
* [squashfs-tools-static](https://github.com/VHSgunzo/squashfs-tools-static)
* [squashfuse-static](https://github.com/VHSgunzo/squashfuse-static)
* [static-curl](https://github.com/moparisthebest/static-curl)
* [tar-static](https://github.com/VHSgunzo/tar-static)
* [which-static](https://github.com/VHSgunzo/which-static)
* [xorg-xhost-static](https://github.com/VHSgunzo/xorg-xhost-static)
* [xz-static](https://github.com/VHSgunzo/xz-static)
* [minos-static](https://github.com/minos-org/minos-static)
* [aria2-static-build](https://github.com/abcfy2/aria2-static-build)
* [fakeroot](https://github.com/mackyle/fakeroot)
* [fakechroot](https://github.com/dex4er/fakechroot)
* [glibc-eac-rc](https://github.com/DissCent/glibc-eac-rc)
* [MEGAcmd](https://github.com/meganz/MEGAcmd)
* [fuse-overlayfs](https://github.com/containers/fuse-overlayfs)

## Projects based on RunImage:
* [stable-diffusion](https://github.com/VHSgunzo/stable-diffusion)
