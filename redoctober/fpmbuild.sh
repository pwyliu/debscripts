#!/bin/bash
set -e

# script varzzzz
CWD=$(pwd)
DOWNLOAD_URL="https://assets.ho.kanetix.com/redoctober"
README_URL="https://raw.githubusercontent.com/cloudflare/redoctober/master/README.md"
ASSETDIR="assets"
PACKAGE_NAME="redoctober"
BUILD_DIR="build"

# Meta
LICENSE="BSD"
VENDOR="Kanetix"
MAINTAINER="<paul@kanetix.ca>"
HOMEPAGE="https://github.com/cloudflare/redoctober"
DESCRIPTION="Go server for two-man rule style file encryption and decryption."

# Red October has no versions right now. Use 0.0.0-kanetix$OURBUILD temporarily.
VERSION="0.0.0-kanetix1"

# Set up dirs and download bin
mkdir -p ${BUILD_DIR}/opt/redoctober
wget ${DOWNLOAD_URL} -O ${BUILD_DIR}/opt/redoctober/redoctober
chmod 0755 ${BUILD_DIR}/opt/redoctober/redoctober
wget ${README_URL} -O ${BUILD_DIR}/opt/redoctober/README.md
chmod 0644 ${BUILD_DIR}/opt/redoctober/README.md

# Engage
cd ${CWD}
fpm -s dir \
    -t deb \
    -n ${PACKAGE_NAME} \
    -v ${VERSION} \
    -C ${BUILD_DIR} \
    -p ${PACKAGE_NAME}-${VERSION}.deb \
    --license ${LICENSE} \
    --maintainer ${MAINTAINER} \
    --url ${HOMEPAGE} \
    --vendor ${VENDOR} \
    --description "$DESCRIPTION" \
    --deb-upstart=${ASSETDIR}/upstart/redoctober \
    --after-install=${ASSETDIR}/postinst.sh \
    --before-install=${ASSETDIR}/preinst.sh \
    --after-remove=${ASSETDIR}/postrm.sh \
    --before-remove=${ASSETDIR}/prerm.sh \
    --edit \
    opt/