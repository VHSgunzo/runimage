# Maintainer: VHSgunzo <vhsgunzo.github.io>

pkgname='runimage-utils'
pkgver='0.39.1'
pkgrel='5'
pkgbase="$pkgname"
pkgdesc='Utilities and scripts for RunImage container'
url="https://github.com/VHSgunzo/runimage"
arch=('any')
license=('MIT')
source=('runimage-utils.tar.gz')
sha256sums=('SKIP')
depends=('pacutils')

package() {
  rm "$srcdir/$source"
  find "${srcdir}" -type f -name '.keep' -exec rm -f {} \;
  cp -rf "${srcdir}/"* "${pkgdir}/"
}
