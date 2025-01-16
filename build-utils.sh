#!/bin/bash
set -e
cd "$(dirname "$(readlink -f "$0" 2>/dev/null)" 2>/dev/null)"
echo "= create runimage-utils.tar"
tar -cf runimage-utils.tar -C . rootfs
echo "= create archlinux package"
makepkg -fsCc --noconfirm --nodeps
rm -f runimage-utils.tar
