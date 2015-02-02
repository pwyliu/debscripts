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

vips_version="7.42.1"
vips_build_dir="vips_build"
vips_download_url="http://www.vips.ecs.soton.ac.uk/supported/current/vips-${vips_version}.tar.gz"
vips_deps=(
    "libxml2-dev"
    "libglib2.0-dev"
    "gettext"
    "pkg-config"
    "zlib1g-dev"
    "libfreetype6-dev"
    "libfontconfig1-dev"
    "libice-dev"
    "libjpeg-dev"
    "libexif-gtk-dev"
    "libtiff4-dev"
    "libfftw3-dev"
    "liblcms2-dev"
    "libpng12-dev"
    "libmagickcore-dev"
    "libmagickwand-dev"
    "libpango1.0-dev"
    "libmatio-dev"
    "libcfitsio3-dev"
    "libopenexr-dev"
    "python-all-dev"
    "python-dev" 
)

package_build_dir="deb_src"
package_deploy_dir="usr/local"
package_asset_dir="${cwd}/assets"

package_name="500px-vips"
package_maintainer="pliu@500px.com"
package_vendor="500px"
package_url="http://www.vips.ecs.soton.ac.uk/index.php"
package_desc="VIPS is a free image processing system."
package_epoch=1
package_version="${vips_version}-$(lsb_release --codename --short)1"
package_deps=(
    "libxml2 (>= 2.7.4)"
    "libc6 (>= 2.11)"
    "libgcc1 (>= 1:4.1.1)"
    "libglib2.0-0 (>= 2.22.0)"
    "libstdc++6 (>= 4.6)"
    "libjpeg-turbo8"
    "libexif12"
    "libtiff4"
    "libfftw3-3"
    "liblcms2-2 (>= 2.2+git20110628-2)"
    "libpng12-0 (>= 1.2.13-4)"
    "libmagickcore4 (>= 8:6.6.9.7)"
    "libpango1.0-0 (>= 1.14.0)"
    "libmatio0"
    "libcfitsio3 (>= 3.060)"
    "libopenexr6 (>= 1.6.1)"
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

cd ${cwd}
[[ ! -d ${logdir} ]] && mkdir -p ${logdir}
[[ -d ${vips_build_dir} ]] && rm -rf ${vips_build_dir}
[[ -d ${package_build_dir} ]] && rm -rf ${package_build_dir}
[[ -d ${package_asset_dir} ]] || die "Asset directory not found."

# Download and extract tarball
if [[ ! -d vips-${vips_version} ]]; then
    log "Downloading ${vips_download_url}"
    wget ${vips_download_url}
    tar -xzf vips-${vips_version}.tar.gz > /dev/null
fi

# Install deps
log "Installing build dependencies"
apt-get install -qq -y "${script_deps[@]}"
apt-get install -qq -y "${vips_deps[@]}"

log "Installing FPM"
gem install fpm --no-ri --no-rdoc --quiet

# Build project
log "Building VIPS"
cd ${cwd}/vips-${vips_version}
./configure --prefix=${cwd}/${vips_build_dir} > ${logdir}/configure.log 2>&1
make clean > ${logdir}/makeclean.log 2>&1
make > ${logdir}/make.log 2>&1
make install > ${logdir}/makeinstall.log 2>&1

# Build deb
log "Copying files to ${package_build_dir}"
cd ${cwd}
mkdir -p ${package_build_dir}/${package_deploy_dir}
cp -R ${vips_build_dir}/* ${package_build_dir}/${package_deploy_dir}/

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
