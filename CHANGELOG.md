# v0.38.3

* Update `README.md`
* Update `CHANGELOG.md`
* Fix bash suspending when `UNSHARE_PIDS`
* Add checking `/dev/net/tun` when `SANDBOX_NET`
* Fix bind `$HOME/.Xauthority` on non standard home path
* Update [static](https://github.com/VHSgunzo/runimage-static/releases/tag/v0.38.3) v0.38.3
* Add `mknod` from [coreutils](https://github.com/VHSgunzo/coreutils-static)
* Replace [notify-send-static](https://github.com/VHSgunzo/notify-send-static) with [notify-send-rs](https://github.com/VHSgunzo/notify-send-rs) v0.0.1
* Remove `aria2c` from `static`
* Add automatic search of the `SANDBOX_HOME` directory
* Add update skipping RunImage rebuild if there are no package updates
* Test on [BlendOS](https://blendos.co/)
* Add [hostexec](https://github.com/VHSgunzo/runimage/blob/main/rootfs/usr/bin/hostexec) arg `--help|-h` Show this usage info
* Add [hostexec](https://github.com/VHSgunzo/runimage/blob/main/rootfs/usr/bin/hostexec) arg `--superuser|-su` Execute command as superuser
* Add [hostexec](https://github.com/VHSgunzo/runimage/blob/main/rootfs/usr/bin/hostexec) arg `--interactive|-i` Execute interactive command (with input prompt)
* Update `print_help()`
* Add bind `/var/lib/dbus/machine-id`
* Remove `SYS_ARIA2C` `ARIA2C`
* Add `aria2c` `wget` `curl` to `try_dl()`
* Remove `MEGAcmd` repository
* Add `get_dbus_session_bus_address()`

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
* [runimage superlite](https://github.com/VHSgunzo/runimage/releases/download/v0.38.2/runimage.superlite) | [pkg_list-superlite.txt](https://github.com/VHSgunzo/runimage/releases/download/v0.38.2/pkg_list-superlite.txt)
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
* [runimage superlite](https://github.com/VHSgunzo/runimage/releases/download/v0.38.1/runimage.superlite) | [pkg_list-superlite.txt](https://github.com/VHSgunzo/runimage/releases/download/v0.38.1/pkg_list-superlite.txt)
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
* [runimage superlite](https://github.com/VHSgunzo/runimage/releases/download/v0.38/runimage.superlite) | [pkg_list-superlite.txt](https://github.com/VHSgunzo/runimage/releases/download/v0.38/pkg_list-superlite.txt)
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
