#!/bin/bash
set -e

case "$1" in
configure)
    if ! getent passwd gaproxy >/dev/null; then
        adduser --system --group --no-create-home \
         --home /opt/google_auth_proxy --shell /bin/false \
         --gecos "google auth proxy user" gaproxy
    fi
    chown -R gaproxy:gaproxy /opt/google_auth_proxy

    chown root:root /etc/default/google_auth_proxy
    chown root:root /etc/init/google_auth_proxy.conf
    ;;
esac
