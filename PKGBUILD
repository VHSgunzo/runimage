# Maintainer: VHSgunzo <vhsgunzo.github.io>

pkgname='runimage-utils'
pkgver='0.40.9'
pkgrel='2'
pkgdesc='Utilities and scripts for RunImage container'
url="https://github.com/VHSgunzo/runimage"
arch=('any')
license=('MIT')
source=('runimage-utils.tar')
sha256sums=('SKIP')
depends=('pacutils')
install='utils.install'

package() {
  find "${srcdir}" -type f -name '.keep' -exec rm -f {} \;
  cp -arTf --no-preserve=ownership "$srcdir/rootfs" "$pkgdir"
}
