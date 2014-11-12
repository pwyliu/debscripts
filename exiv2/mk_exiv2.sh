#!/bin/bash
set -euo pipefail

# Generic functions
function log {
    printf "$(date) $*\n"
}

function die {
    log "ERROR: $*"
    exit 2
}

# Setup
cwd="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
logdir="${cwd}/logs"
script_deps=("build-essential" "rubygems")

src_version="0.24"
src_build_dir="src_build"
src_download_url="http://www.exiv2.org/exiv2-${src_version}.tar.gz"

src_tarball="exiv2-${src_version}.tar.gz"
src_extracts_to="exiv2-${src_version}"

src_deps=(
    "zlib1g-dev"
    "gettext"
    "libexpat1-dev"
)

package_build_dir="deb_src"
package_deploy_dir="usr/local"
package_asset_dir="${cwd}/assets"

package_name="500px-exiv2"
package_maintainer="pliu@500px.com"
package_vendor="500px"
package_url="http://www.exiv2.org"
package_desc="Exiv2 is a C++ library and a command line utility to manage image metadata."
package_epoch=1
package_version="${src_version}-$(lsb_release --codename --short)1"

package_deps=(
    "libc6 (>= 2.14)"
    "libexpat1 (>= 1.95.8)"
    "libgcc1 (>= 1:4.1.1)"
    "libstdc++6 (>= 4.6)"
    "zlib1g (>= 1:1.1.4)"
)

# TEMP - trusty isn't tested yet
if [[ $(lsb_release --codename --short) != "precise" ]]; then
    echo "Only supported on precise"
    exit
fi

# Checks
if [[ "$EUID" -ne 0 ]]; then 
    echo "Please run as root"
    exit
fi

# Engage
log "Starting build"

cd ${cwd}
[[ ! -d ${logdir} ]] && mkdir -p ${logdir}
[[ -d ${src_build_dir} ]] && rm -rf ${src_build_dir}
[[ -d ${package_build_dir} ]] && rm -rf ${package_build_dir}
[[ -d ${package_asset_dir} ]] || die "Asset directory not found."

# Download tarball
if [[ -f ${src_tarball} ]]; then
    log "Found a tarball, skipping download."
else
    log "Downloading ${src_download_url}"
    wget ${src_download_url}
fi

# Extract tarball
log "Extracting ${src_tarball}"
if [[ -d ${src_extracts_to} ]]; then
    rm -rf ${src_extracts_to}
fi
tar -xzf ${src_tarball} > /dev/null

# Install deps
log "Installing build dependencies"
apt-get install -qq -y "${script_deps[@]}"
apt-get install -qq -y "${src_deps[@]}"

log "Installing FPM"
gem install fpm --no-ri --no-rdoc --quiet

# Build project
log "Building Package"
cd ${cwd}/${src_extracts_to}
./configure --prefix=${cwd}/${src_build_dir} > ${logdir}/configure.log 2>&1
make > ${logdir}/make.log 2>&1
make install > ${logdir}/makeinstall.log 2>&1

# Build deb
log "Copying files to ${package_build_dir}"
cd ${cwd}
mkdir -p ${package_build_dir}/${package_deploy_dir}
cp -R ${src_build_dir}/* ${package_build_dir}/${package_deploy_dir}/

# FPM
log "Running FPM"
fpm_args=(-s dir)
fpm_args+=(-t deb)
fpm_args+=(-n ${package_name})
fpm_args+=(-v ${package_version})
fpm_args+=(-C ${package_build_dir})
fpm_args+=(-p ${package_name}_${package_version}.deb)
for i in "${package_deps[@]}"
do
    fpm_args+=(-d "${i}")
done
fpm_args+=(--epoch ${package_epoch})
fpm_args+=(--vendor ${package_vendor})
fpm_args+=(--maintainer ${package_maintainer})
fpm_args+=(--url "${package_url}")
fpm_args+=(--description "${package_desc}")
fpm_args+=(--after-install=${package_asset_dir}/postinst.sh)
fpm_args+=(--after-remove=${package_asset_dir}/postrm.sh)
fpm_args+=(--no-deb-use-file-permissions)
fpm_args+=(
    ${package_deploy_dir}/bin
    ${package_deploy_dir}/include
    ${package_deploy_dir}/lib
    ${package_deploy_dir}/share
)

fpm "${fpm_args[@]}" > ${logdir}/fpm.log 2>&1
log "Finished"