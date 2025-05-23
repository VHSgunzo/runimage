# v0.41.2

* Update [runimage-utils](https://github.com/VHSgunzo/runimage.git) package
* Update [runimage-tini](https://github.com/VHSgunzo/runimage-tini.git) package
* Add [tini option](https://github.com/VHSgunzo/tini/commit/2b1264629e5535d3291729c5510d794ab771fb83) for kill all descendant processes when the main child exits
* Minor fixes

# v0.41.1

* Update [sharun](https://github.com/VHSgunzo/sharun) [v0.6.5](https://github.com/VHSgunzo/sharun/releases/tag/v0.6.5)
* Update [uruntime](https://github.com/VHSgunzo/uruntime) [v0.3.9](https://github.com/VHSgunzo/uruntime/releases/tag/v0.3.9)
* Update [runimage-static](https://github.com/VHSgunzo/runimage-static) package
* Update [runimage-utils](https://github.com/VHSgunzo/runimage.git) package
* Create [runimage-cpids](https://github.com/VHSgunzo/runimage-cpids.git) A utility for tracking child processes of the runimage container
* Remove monitoring thread of running processes
* Сhange logic of tracking running processes and `rim-psmon`
* Reduced CPU utilization in idle time
* Remove `noatime` fuse mount options: https://github.com/pkgforge-dev/Lutris-AppImage/issues/7

# v0.40.9

* Update [sharun](https://github.com/VHSgunzo/sharun) [v0.6.3](https://github.com/VHSgunzo/sharun/releases/tag/v0.6.3)
* Update [uruntime](https://github.com/VHSgunzo/uruntime) [v0.3.6](https://github.com/VHSgunzo/uruntime/releases/tag/v0.3.6)
* Update [runimage-static](https://github.com/VHSgunzo/runimage-static) package
* Update [runimage-utils](https://github.com/VHSgunzo/runimage.git) package
* Add env var `RIM_BUILD_DWFS_HFILE=/path` DwarFS hotness list file for creating DwarFS runimage
* Add `memory-limit=auto` for creating DwarFS runimage
* Add the ability to use other docker registries for `getdimg`
* Update `README` for [RunImage build](https://github.com/VHSgunzo/runimage?tab=readme-ov-file#runimage-build)
* Minor fixes

# v0.40.8

* Update [sharun](https://github.com/VHSgunzo/sharun) [v0.6.2](https://github.com/VHSgunzo/sharun/releases/tag/v0.6.2)
* Update [uruntime](https://github.com/VHSgunzo/uruntime) [v0.3.4](https://github.com/VHSgunzo/uruntime/releases/tag/v0.3.4)
* Update [runimage-static](https://github.com/VHSgunzo/runimage-static) package
* Update [runimage-utils](https://github.com/VHSgunzo/runimage-utils.git) package
* Update `rim-dinteg` (add new path for search icons)
* Add `categorize=hotness` for creating DwarFS runimage
* Minor fixes

# v0.40.7

* Update [sharun](https://github.com/VHSgunzo/sharun) [v0.5.6](https://github.com/VHSgunzo/sharun/releases/tag/v0.5.6)
* Update [uruntime](https://github.com/VHSgunzo/uruntime) [v0.3.1](https://github.com/VHSgunzo/uruntime/releases/tag/v0.3.1)
* Update [runimage-static](https://github.com/VHSgunzo/runimage-static) package
* Update [runimage-utils](https://github.com/VHSgunzo/runimage-utils.git) package
* Update [fake-systemd](https://github.com/VHSgunzo/runimage-fake-systemd) package
* Update [runimage-mirrorlist](https://github.com/VHSgunzo/runimage-mirrorlist) package
* Update [fake-sudo-pkexec](https://github.com/VHSgunzo/runimage-fake-sudo-pkexec) package
* Add `Void Lnux` support for `rim-desktop`
* Add `-d, --dinteg-dir /path` Desktop integration directory (env: `RIM_DINTEG_DIR=/path`) for `rim-dinteg`
* Remove `[RunImage]` from name of integrated desktops
* Reduce `DwarFS` RAM usage and speedup startup
* Revert `Yandex Cloud` mirrors
* Update `README`
* Minor fixes

# v0.40.6

* Update [sharun](https://github.com/VHSgunzo/sharun) [v0.2.9](https://github.com/VHSgunzo/sharun/releases/tag/v0.2.9)
* Update [runimage-static](https://github.com/VHSgunzo/runimage-static) package
* Update [runimage-utils](https://github.com/VHSgunzo/runimage-utils.git) package
* Update [runimage-ssrv](https://github.com/VHSgunzo/runimage-ssrv) package
* Send output from all `_msg()` functions to `stderr`
* Update fix `GameMode` pacman hook
* Fix `rim-exec` env vars for non ssrv childs
* Minor fixes

# v0.40.5

* Fix downloading NVIDIA Data Center GPU Driver
* Update [sharun](https://github.com/VHSgunzo/sharun) [v0.2.8](https://github.com/VHSgunzo/sharun/releases/tag/v0.2.8)
* Update [fake-systemd](https://github.com/VHSgunzo/runimage-fake-systemd) package
* Update [runimage-static](https://github.com/VHSgunzo/runimage-static) package
* Update [runimage-utils](https://github.com/VHSgunzo/runimage-utils.git) package
* Fix disabling Bubblewrap overlay if failed to start with it
* Update example of `steam` packaging
* Update `rim-bootstrap`
* Minor fixes

# v0.40.4

* Fix processes killing with `rim-kill`
* Add case insensitive for `rim-dindeg`
* Update [uruntime](https://github.com/VHSgunzo/uruntime) [v0.1.3](https://github.com/VHSgunzo/uruntime/releases/tag/v0.1.3)
* Update [sharun](https://github.com/VHSgunzo/sharun) [v0.2.6](https://github.com/VHSgunzo/sharun/releases/tag/v0.2.6)
* Update [runimage-static](https://github.com/VHSgunzo/runimage-static) package
* Update [runimage-utils](https://github.com/VHSgunzo/runimage-utils.git) package
* Update usage: add `RIM_SYS_BWRAP=1` Using system bwrap
* Update usage: add `RIM_SYS_SQFUSE=1` Using system squashfuse
* Update usage: add `RIM_SYS_UNSQFS=1` Using system unsquashfs
* Update usage: add `RIM_SYS_MKSQFS=1` Using system mksquashfs
* Update usage: add `RIM_SYS_UNIONFS=1` Using system unionfs
* Update usage: add `RIM_SYS_SLIRP=1` Using system slirp4netns
* Update usage: add `RIM_SYS_GOCRYPTFS=1` Using system gocryptfs
* Update `rim-bootstrap`
* Minor fixes

# v0.40.3

* Fix processes monitoring
* Disable Bubblewrap overlay if failed to start with it for `RIM_IN_SAME_PTY` or on `TTY`
* Update example of `steam` packaging
* Update usage: add `RIM_IN_SAME_PTY=1` Start shell session in same PTY
* Update usage: add `RIM_TTY_ALLOC_PTY=1` Allocate PTY for shell session on TTY
* Minor fixes

# v0.40.2

* Fix `ssrv` background hang on system with legacy forking
* Disable Bubblewrap overlay if OVERFS_DIR on overlayfs
* Disable Bubblewrap overlay if failed to start with it
* Update [fake-systemd](https://github.com/VHSgunzo/runimage-fake-systemd) package
* Update [runimage-utils](https://github.com/VHSgunzo/runimage-utils.git) package
* Update [runimage-rootfs](https://github.com/VHSgunzo/runimage-rootfs) package
* Update [runimage-ssrv](https://github.com/VHSgunzo/runimage-ssrv) package
* Add example of `steam` packaging
* Update CI
* Update rim-bootstrap
* Disable `RIM_SHARE_ICONS` and `RIM_AUTORUN` for `rim-dinteg`

# v0.40.1

* Add `aarch64` support
* [Patch](https://github.com/VHSgunzo/bubblewrap-static/blob/main/caps.patch) nested bubblewrap containerization
* Create new runtime ([uruntime](https://github.com/VHSgunzo/uruntime)) for support [DwarFS](https://github.com/mhx/dwarfs) and [SquashFS](https://docs.kernel.org/filesystems/squashfs.html)
* Add [DwarFS](https://github.com/mhx/dwarfs) filesystem support and use it  by default with zstd compression
* Replace [runimage-runtime-static](https://github.com/VHSgunzo/runimage-runtime-static) with [runimage-uruntime](https://github.com/VHSgunzo/runimage-uruntime)
* Create [sharun](https://github.com/VHSgunzo/sharun) for replace static utils in [runimage-static](https://github.com/VHSgunzo/runimage-static.git)
* Create [ssrv](https://github.com/VHSgunzo/ssrv) for connect to running containers
* Replace old method for `hostexec` and use [ssrv](https://github.com/VHSgunzo/ssrv) for it
* Add [tini](https://github.com/krallin/tini) for control container processes ([tini-static](https://github.com/VHSgunzo/tini-static))
* Remove `ALLOW_BG` env var (now you can send whole runimage to background with processes control)
* Improved child processes control
* Remove `NO_RUNDIR_BIND`
* Fix bug with `MangoHud` and `vkBasalt` in `DXVK`
* Add continuous bootstrap CI
* Fix exit code for `rim-desktop`
* Fix input hang when exit from RunImage desktop on `TTY`
* Fix empty apps menu in RunImage desktop
* Add `/usr/bin/vendor_perl` to `PATH`
* Rename all config env vars with prefix `RIM_*`
* Rename all RunImage args `rim-*`
* Add disabling `RIM_SANDBOX_NET` if `SUID Bubblewrap` is used
* Add support for `debian based` rootfs
* Add support for `alpine based` rootfs
* Add support for `void based` rootfs
* Add `RIM_UNSHARE_LOCALTIME` env var Unshares localtime from the host (/etc/localtime)
* Fix `RIM_UNSHARE_USERS` for group
* Add `RIM_UNSHARE_NSS` env var Unshares NSS from the host (/etc/nsswitch.conf)
* Add `RIM_DINTEG` env var Enable desktop integration pacman hook
* Update static `bubblewrap` [v0.11.0](https://github.com/VHSgunzo/bubblewrap-static/releases/tag/v0.11.0)
* Update `fake-nvidia-driver` [v0.9](https://github.com/VHSgunzo/runimage-fake-nvidia-driver/releases/tag/v0.9)
* Update [Run-wrapper](https://github.com/VHSgunzo/Run-wrapper.git) package
* Update [runimage-static](https://github.com/VHSgunzo/runimage-static.git) package
* Update [runimage-utils](https://github.com/VHSgunzo/runimage-utils.git) package
* Update [runimage-mirrorlist](https://github.com/VHSgunzo/runimage-mirrorlist) package
* Update [runimage-rootfs](https://github.com/VHSgunzo/runimage-rootfs) package
* Update [fake-systemd](https://github.com/VHSgunzo/runimage-fake-systemd) package
* Update [fake-sudo-pkexec](https://github.com/VHSgunzo/runimage-fake-sudo-pkexec) package
* Update [runimage-openssh](https://github.com/VHSgunzo/runimage-openssh) package
* Update `pacman` hooks
* Remove default RunImage configs
* Add `getdimg` script For download docker container images
* Add `httpfw` script For expose a local HTTP port to the internet
* Add `tcpfw` script For expose a local TCP port to the internet
* Add `rim-bootstrap` script For bootstrap new runimage
* Add `rim-dinteg` script For desktop integration
* Add `rim-shrink` script For shrinking unnecessary files
* Add `REUIDDIR` env var RunImage EUID working directory
* Add `RUNTMPDIR` env var RunImage RUNPIDs working directory
* Add `RUNPIDDIR` env var RunImage RUNPID working directory
* Add `REALRUNSRC` env var Real path to `RUNSRC`
* Disable non-error RunImage notification by default (`RIM_NOTIFY=1` env var)
* Add ability to create `Nvidia driver` image from local libs (`RIM_SYS_NVLIBS=1` env var)
* Add `RIM_SYS_NVLIBS` env var Try to use system Nvidia libraries
* Add `RIM_NO_32BIT_NVLIBS_CHECK` env var Disable 32-bit Nvidia libraries check
* Add ability to port forwarding in network sandbox mode (`RIM_SNET_PORTFW` env var) with patched [chisel](https://github.com/VHSgunzo/chisel)
* Add [runimage-chisel](https://github.com/VHSgunzo/runimage-chisel) package
* Add `RIM_SNET_DROP_CIDRS` env var For drop access to host CIDR's in network sandbox mode
* Add `RIM_SNET_TAPIP` env var For set TAP interface IP in network sandbox mode
* Add usage and args flags to all RunImage stripts
* Redesigned the process of updating and subsequent rebuild of the container
* Add `RIM_UPDATE_CLEANUP` env var Run rim-shrink --pkgcache after update
* Add `RIM_UPDATE_SHRINK` env var Run rim-shrink --all after update
* Add ability to en/decrypt rootfs with [gocryptfs](https://github.com/rfjakob/gocryptfs)
* Add ability to start autorun app from PATH
* Add ability to execute commands in one container (`RIM_RUN_IN_ONE=1` env var)
* Add ability to specify the compression filesystem for runimage build (`RIM_CMPRS_FS={sqfs|dwfs}` env var)
* Add ability to specify the compression filesystem block size for runimage build (`RIM_CMPRS_BSIZE={1M|20}` env var)
* Add ability to rename RunImage with `*.RunImage` or `*.rim` extension
* Add ability to use custom rootfs (`RIM_ROOTFS=/path/rootfs` env var)
* Add ability to specify custom OverlayFS (`RIM_OVERFSDIR=/path/overlayfs` env var)
* Add check for `apparmor_restrict_unprivileged_userns`
* Enable Bubblewrap overlay by default for OverlayFS mode (disable with `RIM_NO_BWRAP_OVERLAY=1` env var)
* Add `RIM_UNSHARE_TMP` env var for unshare host `/tmp`
* Add `RIM_UNSHARE_TMPX11UNIX` env var for unshare host `/tmp/.X11-unix`
* Add `RIM_HOST_TOOLS` env var Enables specified commands from the host
* Add `RIM_HOST_XDG_OPEN` env var Enables xdg-open from the host
* Add `RIM_UNSHARE_HOSTNAME` env var Unshares `UTS namespace` and `hostname`
* Add `RIM_UNSHARE_HOSTS` env var Unshares host `/etc/hosts`
* Add `RIM_UNSHARE_RESOLVCONF` env var Unshares host `/etc/resolv.conf`
* Add `RIM_SHARE_PKGCACHE` env var Shares host packages cache
* Add `RIM_BIND` env var Binds specified paths to the container
* Add `RIM_BIND_PWD` env var Binds `$PWD` to the container
* Add `RIM_WAIT_RPIDS_EXIT` env var Wait for all processes to exit
* Add `RIM_EXEC_SAME_PWD` env var Use same `$PWD` for `rim-exec` and `hostexec`
* Rename env var `ARGV0` to `ARG0` (fix `zsh` issue)
* Minor fixes and changes

**=======================================================================================**

# v0.39.1

* Update `rootfs` v0.39.1 23.08.29
* Rename `superlite` to `lwrun`
* Update static `bubblewrap` [v0.8.0.r20](https://github.com/VHSgunzo/bubblewrap-static/releases/tag/v0.8.0.r20)
* Update static `bash` [v5.2.015-1.2.3-2](https://github.com/robxu9/bash-static/releases/tag/5.2.015-1.2.3-2)
* Update static `coreutils` [v9.3](https://github.com/VHSgunzo/coreutils-static/releases/tag/v9.3)
* Update static `grep` [v3.11](https://github.com/VHSgunzo/grep-static/releases/tag/v3.11)
* Update static `procps` [v4.0.3.r31](https://github.com/VHSgunzo/procps-static/releases/tag/v4.0.3)
* Update static `sed` [v4.9](https://github.com/VHSgunzo/sed-static/releases/tag/v4.9)
* Update static `util-linux` [v2.39](https://github.com/VHSgunzo/util-linux-static/releases/tag/v2.39)
* Update static `squashfs-tools` [v4.6.1](https://github.com/VHSgunzo/squashfs-tools-static/releases/tag/v4.6.1)
* Update static `curl` [v8.0.1](https://github.com/moparisthebest/static-curl/releases/tag/v8.0.1)
* Update staticx `xorg-xhost` [v1.0.9](https://github.com/VHSgunzo/xorg-xhost-static/releases/tag/v1.0.9-alpine) (now its on musl)
* Update static `xz` [v5.5.0alpha](https://github.com/VHSgunzo/xz-static/releases/tag/v5.5.0)
* Update static `ptyspawn` [v0.0.5](https://github.com/VHSgunzo/ptyspawn/releases/tag/v0.0.5)
* Rename `fake-nvidia-utils`package to [fake-nvidia-driver](https://github.com/VHSgunzo/runimage-fake-nvidia-driver)
* Update `fake-nvidia-driver` [v0.8](https://github.com/VHSgunzo/runimage-fake-nvidia-driver/releases/tag/v0.8)
* Update `Nvidia driver` check/bind functions
* Add `OpenCL` support for [runimage-nvidia-drivers](https://github.com/VHSgunzo/runimage-nvidia-drivers)
* Add [huggingface](https://huggingface.co/runimage/nvidia-drivers) mirror for download runimage nvidia driver image
* Add support for [tesla](https://us.download.nvidia.com/tesla) nvidia drivers
* Replace `iptables` with `iptables-nft`
* Install `nftables` package
* Install `openresolv` package
* Install [Run-wrapper](https://github.com/VHSgunzo/Run-wrapper.git) package
* Install [runimage-static](https://github.com/VHSgunzo/runimage-static.git) package
* Install [runimage-utils](https://github.com/VHSgunzo/runimage-utils.git) package
* Install [runimage-mirrorlist](https://github.com/VHSgunzo/runimage-mirrorlist) package
* Install [runimage-rootfs](https://github.com/VHSgunzo/runimage-rootfs) package
* Install [fake-systemd](https://github.com/VHSgunzo/runimage-fake-systemd) package
* Install [fake-sudo-pkexec](https://github.com/VHSgunzo/runimage-fake-sudo-pkexec) package
* Install [wine-prefix](https://github.com/VHSgunzo/wine-prefix) package to `lwrun`
* Create and install [steam-runtime-libs](https://github.com/VHSgunzo/steam-runtime-libs) package to `lwrun`
* Create `EAC` [patched](https://github.com/VHSgunzo/glibc-eac) `glibc-eac` and `lib32-glibc-eac` (2.37-3)
* Create and install `Reshade Shaders` [reshade-shaders-lw](https://github.com/VHSgunzo/reshade-shaders-lw) to `lwrun`
* Create [portarch](https://github.com/VHSgunzo/portarch) Portable `Arch Linux`
* Create and install [adwaita-icon-theme-41](https://github.com/VHSgunzo/adwaita-icon-theme-41) package to `portarch`
* Update [GE-Proton v8-13](https://github.com/VHSgunzo/ge-proton-lw/releases/tag/v8.13) in `lwrun`
* Replace `palemoon` with `firefox` in `lwrun`
* Remove `mangoapp` and `lib32-mangoapp` in `lwrun`
* Replace `mangohud-lw-git` with `mangohud` `lib32-mangohud` in `lwrun`
* Update [hosts](https://github.com/StevenBlack/hosts) in `lwrun`
* Fix `LatencyFlex` and `cabextract` in `GE-Proton` in `lwrun`
* `LW tray` moved to a separate [repository](https://github.com/VHSgunzo/lw-tray) and package lw-tray added to the [RunImage](https://github.com/VHSgunzo/runimage) container [pacman repository](https://runimage-repo.hf.space/) and installed in `lwrun`
* Fix warnings and errors of setting the root user and group to files when installing and assembling packages
* Replace [fuse-overlayfs](https://github.com/containers/fuse-overlayfs) with [unionfs-fuse](https://github.com/rpodgorny/unionfs-fuse) ([unionfs-fuse-static](https://github.com/VHSgunzo/unionfs-fuse-static/releases))
* Add `noatime` to `OverlayFS` mode
* Fix `OverlayFS` mode in `Porteus`, `EasyOS` and `ZorinOS` (`fuse-overlayfs` cannot read upper dir cannot allocate memory)
* Fix `gpg-agent` connection errors
* Add get `Nvidia` driver version from `/sys/module/nvidia/version`
* Force using internal `static` binaries from `PATH` (see `SYS_TOOLS` var)
* Fix `ldconfig` `nvidia` symlink creation messages
* Add `steam` `pacman` hook (disabling `capabilitis`)
* Add `gamemode` `pacman` hook (start the `daemon` with `gamemoderun`)
* Add `SANDBOX_NET_SHARE_HOST` Creates a network sandbox with access to host loopback
* Add [RunImage pacman repository](https://github.com/runimage/repo)
* Add [RunImage pacman repository mirror](https://runimage-repo.hf.space)
* Add increasing `soft limit` to `hard limit`
* Remove binds `/srv` `/var/local` `/var/games` `/var/opt` `/boot`
* Add `UNSHARE_USERS` Don't bind-mount `/etc/{passwd,group}`
* Add `SHARE_SYSTEMD` Shares `SystemD` from the host
* Add `UNSHARE_DBUS` Unshares `DBUS` from the host
* Add `pacman` hooks for `pamac` (add fake `sudo` wrapper)
* Remove `pacman` hooks: `grub` `dkms` `mkinitcpio` `depmod`
* Remake `ALLOW_BG`
* Add `PORTABLE_HOME_DIR` Specifies a portable home directory and uses it as `$HOME`
* Add `SANDBOX_HOME_DIR` Specifies sandbox home directory and bind it to `/home/$USER` or to `/root`
* Fix `attaching` to `RunImage` container under `root`
* Add `UNSHARE_MODULES` Unshares kernel modules from the host (`/lib/modules`)
* Rename `BWRAP` and `SYS_BWRAP` var to `BUWRAP` and `SYS_BUWRAP` (`steam` use `BWRAP` var and got error if `RunDir` is sandboxed)
* Add `CMPRS_ALGO` Specifies the compression algo for `runimage` build
* Add `ZSDT_CMPRS_LVL` Specifies the compression ratio of the `zstd` algo for `runimage` build
* Add bind `RunDir` to `/var/RunDir`
* Add `NO_RUNDIR_BIND` Disables binding `RunDir` to `/var/RunDir`
* Add ability to update all utilities and binaries in `RunDir` with `pacman`
* Add ability to update custom `RunImage` `rootfs` files with `pacman`
* Speedup to 8x `hostexec` (see `ENABLE_HOSTEXEC`)
* Remove `RUNROOTFSTYPEs` settings from `Run.sh`
* Remake attaching to running container
* Create [runimage-openssh](https://github.com/VHSgunzo/runimage-openssh) package with patch for fix ssh server in RunImage container
* Install [pacutils](https://github.com/andrewgregory/pacutils) and use it for `RunImage update` (also see `/usr/bin/runupdate`)
* Make `RunImage update` in separate `OverlayFS` (OVERFS_ID="upd$(date +"%H%M%S").$RUNPID")
* Remove `FORCE_UPDATE`
* Fix `AUTORUN` for symlinks in `/usr/bin`
* Add `NO_WARN` Disables all warning `runimage` messages
* Cut `ANSI colors` from `notify-sent` `*_msg`
* Add default run option for some `runimage` args
* Add `UNSHARE_DEF_MOUNTS` Unshares default mount points (`/mnt` `/media` `/run/media`)
* Add `UNSHARE_UDEV` Unshares UDEV from the host (`/run/udev`)
* Remove `GDK_BACKEND` and `NO_AT_BRIDGE` env from `bwrun` setenv
* Add `INSIDE_RUNIMAGE=1` var if inside `RunImage`
* Minor fixes
-----------------------------------------------------------------------------------------------------------------------------
* [runimage](https://github.com/VHSgunzo/runimage/releases/download/v0.39.1/runimage) | [pkg_list.txt](https://github.com/VHSgunzo/runimage/releases/download/v0.39.1/pkg_list.txt)
---------------------------------------------------------------------------------------------------------------------------------------------------
## sha256sum:
```
2b9c9858d1bb6f714b3263ff1096e716f40689d60a72b221b3c91504987bc954  runimage
```

**=======================================================================================**

# v0.38.9

* Update rootfs v0.38.9 23.05.07
* Update `lwrap` v0.77.6 in `lwrun` version
* Disable `SANDBOX_NET` for `Lutris Wine` because `MangoHud` bug under `Wayland`
* Update `mangohud-lw` v0.6.9.1.r44.g7b5c0a4 in `superlite` version
* Add installing dependencies for `RunImage` desktop mode `rundesktop`
* Update `Lutris Wine` runtime in `superlite` version
* Test on [VanillaOS](https://vanillaos.org/)
* Minor fixes
---------------------------------------------------------------------------------------------------------------------------------------------------
* [runimage](https://github.com/VHSgunzo/runimage/releases/download/v0.38.9/runimage) | [pkg_list.txt](https://github.com/VHSgunzo/runimage/releases/download/v0.38.9/pkg_list.txt)
* [runimage.superlite](https://github.com/VHSgunzo/runimage/releases/download/v0.38.9/runimage.superlite) | [pkg_list-superlite.txt](https://github.com/VHSgunzo/runimage/releases/download/v0.38.9/pkg_list-superlite.txt)
---------------------------------------------------------------------------------------------------------------------------------------------------
## sha256sum:
```
800740214ebe60d9a682f8f0e15e5d53ed30960ed3ccc88f99eb0570d073755e  runimage
c60237ce1678313b81e81b0143be704321fcc2e0badd2c0298f790eb377e6d1c  runimage.superlite
```
---------------------------------------------------------------------------------------------------------------------------------------------------
The `superlite` version includes all the necessary libraries to run 32-64 bit applications and games, also contains `steam`, `GE-Proton`, `lutris`, `MangoHud`, `VkBasalt`, `gamemode`, `reshade`, `gamescope`,  `latencyflex`, a lightweight file manager `spacefm`, `pluma` editor, `palemoon` browser and others (see `pkg_list-superlite.txt`). This version will be used as a runtime for other projects.

**=======================================================================================**

# v0.38.8

* Update rootfs v0.38.8 23.04.11
* Update `lwrap` v0.77.1 in `superlite` version
* Update [GE-Proton v7-55](https://github.com/VHSgunzo/ge-proton-lw/releases/tag/v7.55) in `superlite` version
* Replace `lib32-mangohud` `mangohud` `mangohud-common` with [mangohud-lw-git](https://github.com/VHSgunzo/mangohud-lw) in `superlite` version
---------------------------------------------------------------------------------------------------------------------------------------------------
* [runimage](https://github.com/VHSgunzo/runimage/releases/download/v0.38.8/runimage) | [pkg_list.txt](https://github.com/VHSgunzo/runimage/releases/download/v0.38.8/pkg_list.txt)
* [runimage.superlite](https://github.com/VHSgunzo/runimage/releases/download/v0.38.8/runimage.superlite) | [pkg_list-superlite.txt](https://github.com/VHSgunzo/runimage/releases/download/v0.38.8/pkg_list-superlite.txt)
---------------------------------------------------------------------------------------------------------------------------------------------------
## sha256sum:
```
05770343552faacc1c9c302bbd67c97adef1ba109203358b765f6c745acb44d1  runimage
780fdbdd7540fe276239557d4954ff35db173711ddb1d2c79d1557951d09c54a  runimage.superlite
```
---------------------------------------------------------------------------------------------------------------------------------------------------
The `superlite` version includes all the necessary libraries to run 32-64 bit applications and games, also contains `steam`, `GE-Proton`, `lutris`, `MangoHud`, `VkBasalt`, `gamemode`, `reshade`, `gamescope`,  `latencyflex`, a lightweight file manager `spacefm`, `pluma` editor, `palemoon` browser and others (see `pkg_list-superlite.txt`). This version will be used as a runtime for other projects.

**=======================================================================================**

# v0.38.7

* Update rootfs v0.38.7 23.04.03
* Update `lwrap` v0.76.9 in `superlite` version
* Update `GE-Proton` v7-53 in `superlite` version
* Install [lsvkdev](https://github.com/VHSgunzo/lsvkdev) to `superlite` version
---------------------------------------------------------------------------------------------------------------------------------------------------
* [runimage](https://github.com/VHSgunzo/runimage/releases/download/v0.38.7/runimage) | [pkg_list.txt](https://github.com/VHSgunzo/runimage/releases/download/v0.38.7/pkg_list.txt)
* [runimage.superlite](https://github.com/VHSgunzo/runimage/releases/download/v0.38.7/runimage.superlite) | [pkg_list-superlite.txt](https://github.com/VHSgunzo/runimage/releases/download/v0.38.7/pkg_list-superlite.txt)
---------------------------------------------------------------------------------------------------------------------------------------------------
## sha256sum:
```
5bbedebe98ef758153dbb1874b4aa214df6932427552e80497383c274d3aae0d  runimage
48fcbf0bb832c46148c7e52972c5996c2f8fec2a1e3be3b383403476e1fac960  runimage.superlite
```
---------------------------------------------------------------------------------------------------------------------------------------------------
The `superlite` version includes all the necessary libraries to run 32-64 bit applications and games, also contains `steam`, `GE-Proton`, `lutris`, `MangoHud`, `VkBasalt`, `gamemode`, `reshade`, `gamescope`,  `latencyflex`, a lightweight file manager `spacefm`, `pluma` editor, `palemoon` browser and others (see `pkg_list-superlite.txt`). This version will be used as a runtime for other projects.

**=======================================================================================**

# v0.38.6

* Update rootfs v0.38.6 23.03.22
* Change the method of checking `/dev/net/tun`
* Remove `blackarch` repository form `superlite` version
* Freeze `reshade-shaders-git` in `superlite` version
* Add `qterminal` `roxterm` `alacritty` `tilix` `st` `cool-retro-term` `sakura` `terminology` `terminator` `tilda` to `hostexec` terminal detector
* Update `GE-Proton` v7-51 in `superlite` version
* Update `lwrap` v0.76.7 in `superlite` version
* Improved file download function `try_dl()`
* Improved `get_nvidia_driver_image()` function
* Update `config/lwrun.rcfg`
---------------------------------------------------------------------------------------------------------------------------------------------------
* [runimage](https://github.com/VHSgunzo/runimage/releases/download/v0.38.6/runimage) | [pkg_list.txt](https://github.com/VHSgunzo/runimage/releases/download/v0.38.6/pkg_list.txt)
* [runimage.superlite](https://github.com/VHSgunzo/runimage/releases/download/v0.38.6/runimage.superlite) | [pkg_list-superlite.txt](https://github.com/VHSgunzo/runimage/releases/download/v0.38.6/pkg_list-superlite.txt)
---------------------------------------------------------------------------------------------------------------------------------------------------
## sha256sum:
```
d11478a3bdc2c672d6eb02bf8d604e56162d12d7faf3b0ffe8daa4f8321ab16c  runimage
d87c8876b0bba848b0cf74407153e0cfb9f7ba8d1cf768a733f4774ee0b45766  runimage.superlite
```
---------------------------------------------------------------------------------------------------------------------------------------------------
The `superlite` version includes all the necessary libraries to run 32-64 bit applications and games, also contains `steam`, `GE-Proton`, `lutris`, `MangoHud`, `VkBasalt`, `gamemode`, `reshade`, `gamescope`,  `latencyflex`, a lightweight file manager `spacefm`, `pluma` editor, `palemoon` browser and others (see `pkg_list-superlite.txt`). This version will be used as a runtime for other projects.

**=======================================================================================**

# v0.38.5

* Update rootfs v0.38.5 23.03.09
* Update `lwrap` v0.76.5 in superlite version
* Update `GE-Proton` v7-50 in superlite version
* Test on [EasyOS](https://easyos.org)
* Change `chaotic-mirrorlist`
---------------------------------------------------------------------------------------------------------------------------------------------------
* [runimage](https://github.com/VHSgunzo/runimage/releases/download/v0.38.5/runimage) | [pkg_list.txt](https://github.com/VHSgunzo/runimage/releases/download/v0.38.5/pkg_list.txt)
* [runimage.superlite](https://github.com/VHSgunzo/runimage/releases/download/v0.38.5/runimage.superlite) | [pkg_list-superlite.txt](https://github.com/VHSgunzo/runimage/releases/download/v0.38.5/pkg_list-superlite.txt)
---------------------------------------------------------------------------------------------------------------------------------------------------
## sha256sum:
```
73c7ea7128ddddae782f110abc0b04d8199dd7d853a0bfb0303e55e401fc4a72  runimage
7f223d5c77c19ffb1e23de1131e26a685350297cbb0fee60da4a3ba22e70ba7d  runimage.superlite
```
---------------------------------------------------------------------------------------------------------------------------------------------------
The `superlite` version includes all the necessary libraries to run 32-64 bit applications and games, also contains `steam`, `GE-Proton`, `lutris`, `MangoHud`, `VkBasalt`, `gamemode`, `reshade`, `gamescope`,  `latencyflex`, a lightweight file manager `spacefm`, `pluma` editor, `palemoon` browser and others (see `pkg_list-superlite.txt`). This version will be used as a runtime for other projects.

**=======================================================================================**

# v0.38.4

* Update rootfs v0.38.4 23.03.04
* Update `EAC` [patched](https://github.com/DissCent/glibc-eac-rc) `glibc` and `lib32-glibc` (2.37-2) to `superlite` version
* Test on [Calculate](https://www.calculate-linux.org/)
* Install `gstreamer-vaapi` `libvdpau-va-gl` `vdpauinfo` `lib32-mesa-vdpau` `lib32-lzo` `nvidia-vaapi-driver` to `superlite` version
* Remove `lutris-wine-git` from `superlite` version
* Install [lwrap](https://github.com/VHSgunzo/lutris-wine/lwrap) [Lutris Wine](https://github.com/VHSgunzo/lutris-wine) wrapper to `superlite` version
* Install [GE-Proton](https://github.com/VHSgunzo/lutris-wine/tree/main/ge-proton) [Lutris Wine](https://github.com/VHSgunzo/lutris-wine) v7-49 to `superlite` version
* Add default `wine` prefix backup for [Lutris Wine](https://github.com/VHSgunzo/lutris-wine) to `superlite` version `/rootfs/opt/lwrap/prefix_backups/defprefix.xz.lwpfx`
* Add [Lutris Wine](https://github.com/VHSgunzo/lutris-wine) runtime libs to `superlite` version `/rootfs/opt/lwrap/runtime`
* Add ability to specify `NVIDIA_DRIVERS_DIR` Nvidia driver images directory
* Add ability to specify `RUNCACHEDIR` Cache directory
* Replace `which` to `which_exe()`
* Add `curl` progress bar to `try_dl()`
* Add `config/lutris.rcfg` `runimage` configuration for `lutris`
* Remove `wait_pid()` and Fix `try_kill()`
* Fix `get_bwpids()`
* Fix sometimes failed creating `SANDBOX_NET` on slow system
* Change `config/sw_runtime.rcfg`
* Install `wmctrl` to `superlite` version
* Add `fix-wtrx` pacman hook to `superlite` version
---------------------------------------------------------------------------------------------------------------------------------------------------
* [runimage](https://github.com/VHSgunzo/runimage/releases/download/v0.38.4/runimage) | [pkg_list.txt](https://github.com/VHSgunzo/runimage/releases/download/v0.38.4/pkg_list.txt)
* [runimage.superlite](https://github.com/VHSgunzo/runimage/releases/download/v0.38.4/runimage.superlite) | [pkg_list-superlite.txt](https://github.com/VHSgunzo/runimage/releases/download/v0.38.4/pkg_list-superlite.txt)
---------------------------------------------------------------------------------------------------------------------------------------------------
## sha256sum:
```
47f8d5987d68860bfa334e6e5502220c5dae5c14eeb2b2e26dcd92c84aa0c84f  runimage
61ac5c7719a15eed02a16a7ccfe738f953776718f5de2b1369dc4b2505da5b59  runimage.superlite
```
---------------------------------------------------------------------------------------------------------------------------------------------------
The `superlite` version includes all the necessary libraries to run 32-64 bit applications and games, also contains `steam`, `GE-Proton`, `lutris`, `MangoHud`, `VkBasalt`, `gamemode`, `reshade`, `gamescope`,  `latencyflex`, a lightweight file manager `spacefm`, `pluma` editor, `palemoon` browser and others (see `pkg_list-superlite.txt`). This version will be used as a runtime for other projects.

**=======================================================================================**

# v0.38.3

* Update rootfs v0.38.3 23.02.19
* Update `README.md`
* Update `CHANGELOG.md`
* Fix bash suspending when `UNSHARE_PIDS`
* Add checking `/dev/net/tun` when `SANDBOX_NET`
* Fix bind `$HOME/.Xauthority` on non standard home path
* Update [static](https://github.com/VHSgunzo/runimage-static/releases/tag/v0.38.3) v0.38.3
* Add `mknod` from [coreutils](https://github.com/VHSgunzo/coreutils-static)
* Add [socat](https://github.com/VHSgunzo/socat-static)
* Replace [notify-send-static](https://github.com/VHSgunzo/notify-send-static) with [notify-send-rs](https://github.com/VHSgunzo/notify-send-rs) v0.0.1
* Remove `aria2c` from `static`
* Add automatic search of the `SANDBOX_HOME` directory
* Add update skipping RunImage rebuild if there are no package updates
* Test on [BlendOS](https://blendos.co/)
* Add [hostexec](https://github.com/VHSgunzo/runimage/blob/main/rootfs/usr/bin/hostexec) arg `--help|-h` Show this usage info
* Add [hostexec](https://github.com/VHSgunzo/runimage/blob/main/rootfs/usr/bin/hostexec) arg `--superuser|-su` Execute command as superuser
* Add [hostexec](https://github.com/VHSgunzo/runimage/blob/main/rootfs/usr/bin/hostexec) arg `--terminal|-t` Execute command in host terminal
* Add [hostexec](https://github.com/VHSgunzo/runimage/blob/main/rootfs/usr/bin/hostexec) arg `--shell|-s` Launch host shell (socat + ptyspawn)
* Update `print_help()`
* Add bind `/var/lib/dbus/machine-id`
* Remove `SYS_ARIA2C` `ARIA2C`
* Add `aria2c` `wget` `curl` to `try_dl()`
* Remove `MEGAcmd` repository
* Add launching `socat` `dbus` proxy if `*_NET*` and `DBUS_SESSION_BUS_ADDRESS` =~ `unix:abstract`
* Add `RUNPPID` Parent PID of `Run.sh` script
* Fix sometimes killing parent PID on container exit if `PID_MAX` is too small
* Add warning and recomendation if `PID_MAX` is less than `4194304`
* Remove `headpid`
* Add [ptyspawn](https://github.com/VHSgunzo/ptyspawn)
* Update [bubblewrap](https://github.com/VHSgunzo/bubblewrap-static/releases/tag/v0.7.0.r8) v0.7.0.r8
* Remove `NO_BWRAP_WAIT`
* Speedup container closing when exec too quickly
* Update [gamemoderun](https://github.com/VHSgunzo/runimage/blob/main/rootfs/usr/bin/gamemoderun) in `superlite` version
* Fix `sudo` installing error in `base` version
* Fix monitoring of running processes
* Update [Run-wrapper v0.0.5](https://github.com/VHSgunzo/Run-wrapper/releases/tag/v0.0.5)
* Add a mechanism for creating a new processes session
* Fix exec background processes with attaching to container and `ALLOW_BG`
* Fix exec background processes with `UNSHARE_PIDS` and `ALLOW_BG`
* Reduce the number of locales in `/etc/locale.gen`
* Reduce the size of the `base` version
* Rename and update internal `config/runimage_sw.rcfg` -> `config/sw_runtime.rcfg`
---------------------------------------------------------------------------------------------------------------------------------------------------
* [runimage](https://github.com/VHSgunzo/runimage/releases/download/v0.38.3/runimage) | [pkg_list.txt](https://github.com/VHSgunzo/runimage/releases/download/v0.38.3/pkg_list.txt)
* [runimage.superlite](https://github.com/VHSgunzo/runimage/releases/download/v0.38.3/runimage.superlite) | [pkg_list-superlite.txt](https://github.com/VHSgunzo/runimage/releases/download/v0.38.3/pkg_list-superlite.txt)
---------------------------------------------------------------------------------------------------------------------------------------------------
## sha256sum:
```
c57e8c3263b4cb911c6f40766901c8682207298aa840bdae3bf713818d90ae29  runimage
724f291f940645ddfa6e5f54152d35691e1041c3e54d16c75d3084a12620c2b8  runimage.superlite
```
---------------------------------------------------------------------------------------------------------------------------------------------------
The `superlite` version includes all the necessary libraries to run 32-64 bit applications and games, also contains `steam`, `lutris`, `MangoHud`, `VkBasalt`, `gamemode`, `reshade`, `gamescope`,  `latencyflex`, a lightweight file manager `spacefm`, `pluma` editor, `palemoon` browser and others (see `pkg_list-superlite.txt`). This version will be used as a runtime for other projects.

**=======================================================================================**

# v0.38.2

* Update rootfs v0.38.2 23.02.02
* Update `README.md`
* Update `CHANGELOG.md`
* Speedup [hostexec](https://github.com/VHSgunzo/runimage/blob/main/rootfs/usr/bin/hostexec)
* Any `SANDBOX_NET`* enables network sandbox
* Rename internal `config/sw_runtime.rcfg` -> `config/runimage_sw.rcfg`
* Add `filesystem` package to `IgnorePkg` in `pacman.conf` (Fixes an update error)
* Enable `CheckSpace` in `pacman.conf`
* Update `chaotic-mirrorlist`
* Add `SANDBOX_HOME` Creates sandbox home directory and bind it to `/home/$USER` or to `/root`
* Add `SANDBOX_HOME_DL` As above, but with binding `$HOME/Downloads` directory
* Add `try_mkhome()`
* Add `RUNCONFIGDIR` RunImage external configs directory
* Add `SANDBOXHOMEDIR` Sandbox homes directory
* Add `PORTABLEHOMEDIR` Portable homes directory
* Move `RUNOVERFSDIR` to `RUNIMAGEDIR`
* Set `Adwaita-dark` as default theme for `superlite`
* Rename `runimage.base` -> `runimage`
* Remove `base` rootfs type, now it's without type (empty rootfs/.type)
* Add standard startup options for `runimage` args
* Standard startup options for `runimage` args are applied after the rcfg config is applied
---------------------------------------------------------------------------------------------------------------------------------------------------
* [runimage](https://github.com/VHSgunzo/runimage/releases/download/v0.38.2/runimage) | [pkg_list.txt](https://github.com/VHSgunzo/runimage/releases/download/v0.38.2/pkg_list.txt)
* [runimage.superlite](https://github.com/VHSgunzo/runimage/releases/download/v0.38.2/runimage.superlite) | [pkg_list-superlite.txt](https://github.com/VHSgunzo/runimage/releases/download/v0.38.2/pkg_list-superlite.txt)
---------------------------------------------------------------------------------------------------------------------------------------------------
## sha256sum:
```
c181deec1ffbdc4ef2a74d1d636314643461a4efaa8e13756b4d88433ceda812  runimage
9b1d9f3d21d9d0ebb22714639adf58fd9ebdc0f64b9e3f998c0d2891d8e525e7  runimage.superlite
```
---------------------------------------------------------------------------------------------------------------------------------------------------
The `superlite` version includes all the necessary libraries to run 32-64 bit applications and games, also contains `steam`, `lutris`, `MangoHud`, `VkBasalt`, `gamemode`, `reshade`, `gamescope`,  `latencyflex`, a lightweight file manager `spacefm`, `pluma` editor, `palemoon` browser and others (see `pkg_list-superlite.txt`). This version will be used as a runtime for other projects.

**=======================================================================================**

# v0.38.1

* Updated rootfs v0.38.1 23.01.29
* Updated `README.md`
* Updated `LICENCE`
* Added `CHANGELOG.md`
* Updated `print_help()`
* Updated [static](https://github.com/VHSgunzo/runimage-static/releases/tag/v0.38.1) v0.38.1
* Removed bash job control in `Run.sh` script
* Removed `bash-rc` hook
* Removed `xterm-rc` hook
* Added `screenshots`
* Removed `NO_DOUBLE_MOUNT`
* Сhanged `cleanup()`
* Removed external usage `FORCE_CLEANUP`
* Сhanged internal `config`'s
* Сhanged `*_INET*` -> `*_NET*`
* Сhanged `NO_NOTIFY` -> `DONT_NOTIFY`
* Сhanged `try_unmount()`
* Сhanged `try_mkdir()`
* Сhanged `bwrun()`
* Сhanged `overlayfs_rm()`
* Сhanged `overlayfs_list()`
* Сhanged [gamemoderun](https://github.com/VHSgunzo/runimage/blob/main/rootfs/usr/bin/gamemoderun)
* Сhanged [runbuild](https://github.com/VHSgunzo/runimage/blob/main/rootfs/usr/bin/runbuild) BUILDKEY to $BASHPID
* Сhanged [rundesktop](https://github.com/VHSgunzo/runimage/blob/main/rootfs/usr/bin/rundesktop) DESKTOP_KEY to $BASHPID
* Сhanged [gtk-2.0/gtkrc](https://github.com/VHSgunzo/runimage/blob/main/rootfs/usr/share/gtk-2.0/gtkrc)
* Сhanged [gtk-3.0/settings.ini](https://github.com/VHSgunzo/runimage/blob/main/rootfs/usr/share/gtk-3.0/settings.ini)
* Сhanged [gtk-4.0/settings.ini](https://github.com/VHSgunzo/runimage/blob/main/rootfs/usr/share/gtk-4.0/settings.ini)
* Changed [pacman.conf](https://github.com/VHSgunzo/runimage/blob/main/rootfs/etc/pacman.conf)
* Added xdg-exo pacman hook [xdg-exo.hook](https://github.com/VHSgunzo/runimage/blob/main/rootfs/usr/share/libalpm/hooks/xdg-exo.hook)
* Added `--run-kill   |--rK` Kill all running runimage containers
* Added `--run-procmon|--rPm {RUNPIDs}` Monitoring of processes running in runimage containers
* Added `--run-attach |--rA  {RUNPID} {args}` Attach to a running runimage container or exec command
* Added `ALLOW_BG` Allows you to run processes in the background and exit the container
* Added `SQFUSE_REMOUNT` Remounts the container using squashfuse (fix MangoHud and VkBasalt bug)
* Added `SYS_SLIRP` Using system slirp4netns
* Added `SLIRP` slirp4netns
* Added `FORCE_UPDATE` to RunImage update `run_update()`
* Added `ENABLE_HOSTEXEC` Enables the ability to execute commands at the host level
* Added `NO_RPIDSMON` Disables the monitoring thread of running processes
* Added `FORCE_UPDATE` Disables all checks when updating
* Added `SANDBOX_NET` Creates a network sandbox
* Added `SANDBOX_NET_CIDR` Specifies tap interface subnet in network sandbox (Def: 10.0.2.0/24)
* Added `SANDBOX_NET_TAPNAME` Specifies tap interface name in network sandbox (Def: eth0)
* Added `SANDBOX_NET_MAC` Specifies tap interface MAC in network sandbox (Def: random)
* Added `SANDBOX_NET_MTU` Specifies tap interface MTU in network sandbox (Def: 1500)
* Added `SANDBOX_NET_HOSTS` Binds specified file to /etc/hosts in network sandbox
* Added `SANDBOX_NET_RESOLVCONF` Binds specified file to /etc/resolv.conf in network sandbox
* Added `BWRAP_ARGS` Array with Bubblewrap arguments (for config file)
* Added `EXEC_ARGS` Array with Bubblewrap exec arguments (for config file)
* Added `NO_BWRAP_WAIT` Disables the delay when closing the container too quickly
* Added export `RUNPID` PID of Run.sh script
* Added [rpidsmon](https://github.com/VHSgunzo/runimage/blob/main/rootfs/usr/bin/rpidsmon) For monitoring of processes running in runimage containers
* Added [hostexec](https://github.com/VHSgunzo/runimage/blob/main/rootfs/usr/bin/hostexec) For execute commands at the host level (see ENABLE_HOSTEXEC)
* Added [headpid](https://github.com/VHSgunzo/runimage/blob/main/headpid.c) v0.0.1
* Added [util-linux](https://github.com/VHSgunzo/util-linux-static) v2.38.1
* Added [importenv](https://github.com/VHSgunzo/importenv) v0.0.6
* Added [slirp4netns](https://github.com/rootless-containers/slirp4netns) v1.2.0
* Updated [runtime](https://github.com/VHSgunzo/runimage-runtime-static) v0.4.6
* Added [Run-wrapper](https://github.com/VHSgunzo/Run-wrapper) ELF wrapper for RunImage `Run.sh` script in the extracted form
* Added `run_attach()`
* Added `force_kill()`
* Added `wait_pid()`
* Added `try_kill()`
* Added `try_upd_rpids()`
* Added `get_child_pids()`
* Added setting of default startup parameters
* Fixed `AUTORUN`
* Added nameserver 1.0.0.1 to `resolv.conf`
* Added [hosts](https://github.com/StevenBlack/hosts)
* Added bind [lastlog](https://github.com/VHSgunzo/runimage/blob/main/rootfs/var/log/lastlog)
* Added bind [wtmp](https://github.com/VHSgunzo/runimage/blob/main/rootfs/var/log/wtmp)
* Changed some `*_msg` in `Run.sh` `rundesktop`
---------------------------------------------------------------------------------------------------------------------------------------------------
* [runimage base](https://github.com/VHSgunzo/runimage/releases/download/v0.38.1/runimage.base) | [pkg_list-base.txt](https://github.com/VHSgunzo/runimage/releases/download/v0.38.1/pkg_list-base.txt)
* [runimage.superlite](https://github.com/VHSgunzo/runimage/releases/download/v0.38.1/runimage.superlite) | [pkg_list-superlite.txt](https://github.com/VHSgunzo/runimage/releases/download/v0.38.1/pkg_list-superlite.txt)
---------------------------------------------------------------------------------------------------------------------------------------------------
## sha256sum:
```
56189af39ef860157dc0c37a0924682a82810ba8e74708790178916b4f4a0a75  runimage.base
f47d882fc25924d2d2e9b83da8c41c185c35a7f4d2577ee91d808b906a0dd466  runimage.superlite
```
---------------------------------------------------------------------------------------------------------------------------------------------------
The `superlite` version includes all the necessary libraries to run 32-64 bit applications and games, also contains `steam`, `lutris`, `MangoHud`, `VkBasalt`, `gamemode`, `reshade`, `gamescope`,  `latencyflex`, a lightweight file manager `spacefm`, `pluma` editor, `palemoon` browser and others (see `pkg_list-superlite.txt`). This version will be used as a runtime for other projects.

**=======================================================================================**

# v0.38

*  Updated rootfs v0.38.22.12.21
* Updated README.md
* Updated Help
* Changed method of embedding RunImage runtime in build/rebuild new RunImage `runbuild`
* Updated `static`
* Fixed `FORCE_CLEANUP`
* Changed RunImage update `--run-update|--rU` `run_update()`
* Changed *_msg() `runbuild` `rundesktop` `Run`
* Enabled  job control in `Run` script
* Added array for `RUN_SHELL`
* Changed `pacman.conf`
* Changed `bash-rc` hook
---------------------------------------------------------------------------------------------------------------------------------------------------
* [runimage base](https://github.com/VHSgunzo/runimage/releases/download/v0.38/runimage.base) | [pkg_list-base.txt](https://github.com/VHSgunzo/runimage/releases/download/v0.38/pkg_list-base.txt)
* [runimage.superlite](https://github.com/VHSgunzo/runimage/releases/download/v0.38/runimage.superlite) | [pkg_list-superlite.txt](https://github.com/VHSgunzo/runimage/releases/download/v0.38/pkg_list-superlite.txt)
---------------------------------------------------------------------------------------------------------------------------------------------------
## sha256sum:
```
cb17e254f3651ae631ab0a0348939168f40245eec6119507a40badf183c8d3f0  runimage.base
a41e1eb42421421dbc5f5df2606ac4f753f0487f1b2d22c19cd39072d094903e  runimage.superlite
```
---------------------------------------------------------------------------------------------------------------------------------------------------
The `superlite` version includes all the necessary libraries to run 32-64 bit applications and games, also contains `steam`, `lutris`, `MangoHud`, `VkBasalt`, `gamemode`, `reshade`, `gamescope`,  `latencyflex`, a lightweight file manager `spacefm`, `pluma` editor, `palemoon` browser and others (see `pkg_list-superlite.txt`). This version will be used as a runtime for other projects.

**=======================================================================================**

# v0.37.9

*  Updated rootfs v0.37.9 22.12.17 15:49:11
* Updated README.md
* Updated Help
* Added short arguments variants
* Changed all long arguments from `--runimage*` to `--run*` and `--overlayfs*` to `--overfs*`
* Added `NO_DOUBLE_MOUNT`
* Added `KEEP_OLD_BUILD`
* Changed method of build/rebuild new RunImage `runbuild`
* Added `RUNSRCNAME` to exports
* Added RunImage update `--run-update|--rU` `run_update()`
* Changed *_msg() `runbuild` `rundesktop` `Run`
* Changed autorun mode `info_msg()`
* Fixed Ctrl+C closing
---------------------------------------------------------------------------------------------------------------------------------------------------
* [runimage base x64](https://github.com/VHSgunzo/runimage/releases/download/v0.37.9/runimage.base.x64) | [pkg_list-base.x64.txt](https://github.com/VHSgunzo/runimage/releases/download/v0.37.9/pkg_list-base.x64.txt)

**=======================================================================================**

# v0.37.8

*  Updated rootfs v0.37.8 2022.12.10 18:24:21
* Updated README.md
* Fixed detection of the real installed nvidia driver in the container
* Changed binding option for nvidia driver libs
* Changed the compression method for nvidia driver images to zstd
* Changed some variables name
* Changed a condition for generating and binding the external cache ld.so.cache for nvidia driver images
* Added AUTORUN array mode in configs
* Added required packages to the repository
* Added sw_runtime.rcfg for [StartWine Launcher](https://github.com/RusNor/StartWine-Launcher)
* Added NO_KILL_FUSE
* Added SETENV_ARGS array
* Added OverlayFS mode (OVERFS_MODE | KEEP_OVERFS | OVERFS_ID)
* Added BUILD_WITH_EXTENSION
* Added --overlayfs-list
* Added --overlayfs-rm
* Added [--runimage-build](https://github.com/VHSgunzo/runimage#buildrebuild-your-own-runimage) ([/bin/runbuild](https://github.com/VHSgunzo/runimage/blob/main/rootfs/bin/runbuild))
* Updated Help
* Changed SELinux check
* Changed [/bin/rundesktop](https://github.com/VHSgunzo/runimage/blob/main/rootfs/bin/rundesktop)
* Changed [/etc/bash.bashrc](https://github.com/VHSgunzo/runimage/blob/main/rootfs/etc/bash.bashrc)
* Changed [/etc/pacman.conf
](https://github.com/VHSgunzo/runimage/blob/main/rootfs/etc/pacman.conf
)
* Added [/bin/transfer](https://github.com/VHSgunzo/runimage/blob/main/rootfs/bin/transfer)
* Added [/bin/webm2gif](https://github.com/VHSgunzo/runimage/blob/main/rootfs/bin/webm2gif)
* Added custom pacman [hooks](https://github.com/VHSgunzo/runimage/tree/main/rootfs/usr/share/libalpm/hooks)
* Tested on [Green Linux](https://greenlinux.ru/)
* Tested on [Grml Linux](https://grml.org/)
* Created and added [superglue](https://github.com/VHSgunzo/superglue)
---------------------------------------------------------------------------------------------------------------------------------------------------
* [runimage base x64](https://github.com/VHSgunzo/runimage/releases/download/v0.37.8/runimage.base.x64) | [pkg_list-base.x64.txt](https://github.com/VHSgunzo/runimage/releases/download/v0.37.8/pkg_list-base.x64.txt)

**=======================================================================================**

# v0.37.7

!! Pre-alpha version | Only for tests !!
---------------------------------------------------------------------------------------------------------------------------------------------------
* Updated rootfs 23.11.2022
* Added  base version ([rootfs](https://github.com/VHSgunzo/runimage-rootfs/releases/tag/v22.11.22.base))
* Updated README.md
* Added definition of the runtime version in unpacked form
* Fixed the definition of the absence of an installed nvidia driver in the container
* Added a condition for generating and binding the external cache ld.so.cache only in packed form
* Added $SHELL selection in the container by RUN_SHELL="/path/shell"
* Fixed a bug in AUTORUN
* Fixed a bug in rundesktop
* Changed gamemode.ini notify
* Added fish configs
* Added required packages to the repository
* Added [MEGAcmd](https://github.com/meganz/MEGAcmd) repository
* Added  python-multipledispatch
* Added  python-pyrr
---------------------------------------------------------------------------------------------------------------------------------------------------
* [runimage full](https://mega.nz/file/sEwmXTbb#6rYOE_t6m4byIL34OPAFSAsdTH5SeHYgmgUjfoDB8wM) | [pkg_list-full.txt](https://github.com/VHSgunzo/runimage/releases/download/v0.37.7/pkg_list-full.txt)
* [runimage base](https://github.com/VHSgunzo/runimage/releases/download/v0.37.7/runimage.base) | [pkg_list-base.txt](https://github.com/VHSgunzo/runimage/releases/download/v0.37.7/pkg_list-base.txt)
* [runimage base x64 only](https://github.com/VHSgunzo/runimage/releases/download/v0.37.7/runimage.base.x64) | [pkg_list-base.x64.txt](https://github.com/VHSgunzo/runimage/releases/download/v0.37.7/pkg_list-base.x64.txt)
* [runimage base zstd](https://github.com/VHSgunzo/runimage/releases/download/v0.37.7/runimage.zst.base)
* [runimage base x64 only zstd](https://github.com/VHSgunzo/runimage/releases/download/v0.37.7/runimage.zst.base.x64)
