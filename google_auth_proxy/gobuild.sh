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

src_version="0.1.0"
src_build_dir="src_build"

# relative to GOPATH
go_bin_path="bin/google_auth_proxy"
go_readme_path="src/github.com/bitly/google_auth_proxy/README.md"
go_get_url="github.com/bitly/google_auth_proxy"

package_build_dir="deb_src"

package_deploy_parent="opt"
package_deploy_dir="google_auth_proxy"

package_asset_dir="${cwd}/assets"
package_name="500px-google_auth_proxy"
package_maintainer="pliu@500px.com"
package_vendor="500px"
package_url="https://github.com/bitly/google_auth_proxy"
package_desc="A reverse proxy that provides authentication using Google OAuth2"
package_epoch=1
package_version="${src_version}-$(lsb_release --codename --short)1"
package_upstart_file="google_auth_proxy"
package_default_file="google_auth_proxy"


# TEMP - trusty isn't tested yet
if [[ $(lsb_release --codename --short) != "precise" ]]; then
    echo "Only supported on precise"
    exit
fi

# Checks - this script assumes you've already got Go installed
if [[ "$EUID" -ne 0 ]]; then 
    echo "Please run as root"
    exit
fi
command -V go > /dev/null || die "Go not found."


# Engage
log "Starting build"
cd ${cwd}
[[ ! -d ${logdir} ]] && mkdir -p ${logdir}
[[ -d ${src_build_dir} ]] && rm -rf ${src_build_dir}
[[ -d ${package_build_dir} ]] && rm -rf ${package_build_dir}
[[ -d ${package_asset_dir} ]] || die "Asset directory not found."
mkdir ${src_build_dir}

# Install deps
log "Installing build dependencies"
apt-get install -qq -y "${script_deps[@]}"

log "Installing FPM"
gem install fpm --no-ri --no-rdoc --quiet

# Go get
log "Go getting..."
go get ${go_get_url} > ${logdir}/go_get.log 2>&1
cp ${GOPATH}/${go_bin_path} ${src_build_dir}/
cp ${GOPATH}/${go_readme_path} ${src_build_dir}/

# Build deb
log "Copying files to ${package_build_dir}"
cd ${cwd}
mkdir -p ${package_build_dir}/${package_deploy_parent}/${package_deploy_dir}
cp -R ${src_build_dir}/* ${package_build_dir}/${package_deploy_parent}/${package_deploy_dir}

# FPM
log "Running FPM"
fpm_args=(-s dir)
fpm_args+=(-t deb)
fpm_args+=(-n ${package_name})
fpm_args+=(-v ${package_version})
fpm_args+=(-C ${package_build_dir})
fpm_args+=(-p ${package_name}_${package_version}.deb)
fpm_args+=(--epoch ${package_epoch})
fpm_args+=(--vendor ${package_vendor})
fpm_args+=(--maintainer ${package_maintainer})
fpm_args+=(--url "${package_url}")
fpm_args+=(--description "${package_desc}")
fpm_args+=(--deb-upstart=${package_asset_dir}/upstart/${package_upstart_file})
fpm_args+=(--deb-default=${package_asset_dir}/default/${package_default_file})
fpm_args+=(--after-install=${package_asset_dir}/postinst.sh)
fpm_args+=(--before-install=${package_asset_dir}/preinst.sh)
fpm_args+=(--after-remove=${package_asset_dir}/postrm.sh)
fpm_args+=(--before-remove=${package_asset_dir}/prerm.sh)
fpm_args+=(--no-deb-use-file-permissions)
fpm_args+=(
    ${package_deploy_parent}
)

fpm "${fpm_args[@]}" > ${logdir}/fpm.log 2>&1
log "Finished"