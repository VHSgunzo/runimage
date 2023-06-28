#!/bin/bash
set -e
cd "$(dirname "$(readlink -f "$0" 2>/dev/null)" 2>/dev/null)"
rm -rf *runimage-utils* pkg src 2>/dev/null
echo "= create runimage-utils.tar.gz"
tar --gzip -acf runimage-utils.tar.gz -C rootfs ./
echo "= create archlinux package"
makepkg -fsCc --noconfirm --nodeps
