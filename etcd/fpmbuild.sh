#!/bin/bash
set -e

CWD=$(pwd)
VERSION="0.3.0"
TYPE_ARCH="linux-amd64"
FILE_EXT=".tar.gz"
DOWNLOAD_URL="https://github.com/coreos/etcd/releases/download/v$VERSION/etcd-v$VERSION-$TYPE_ARCH$FILE_EXT"

if [[ -d etcd-v${VERSION}-${TYPE_ARCH} ]]; then
  if [[ -e etcd-v${VERSION}-${TYPE_ARCH}${FILE_EXT} ]]; then
    rm etcd-v${VERSION}-${TYPE_ARCH}${FILE_EXT}
  fi
  rm -rf etcd-v${VERSION}-${TYPE_ARCH}
fi

wget ${DOWNLOAD_URL}
tar -xvzf etcd-v${VERSION}-${TYPE_ARCH}${FILE_EXT}

cd etcd-v${VERSION}-${TYPE_ARCH}
mkdir -p opt/etcd
mkdir -p etc/etcd
cp etcd* README* opt/etcd/
cp ../etcd.defaultconf etc/etcd/etcd.conf

cd ${CWD}
fpm -s dir \
    -t deb \
    -n etcd \
    -v ${VERSION} \
    -C etcd-v${VERSION}-${TYPE_ARCH} \
    -p etcd-VERSION_ARCH.deb \
    --deb-user=etcd \
    --deb-group=etcd \
    --deb-upstart=etcd \
    --after-install=postinst.sh \
    --before-install=preinst.sh \
    --after-remove=postrm.sh \
    --before-remove=prerm.sh \
    --edit \
    etc/ opt/