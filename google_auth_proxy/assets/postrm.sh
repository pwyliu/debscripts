#!/bin/bash
set -e

case "$1" in
remove | purge)
    echo "Cleaning up"

    # Delete user
    if getent passwd gaproxy >/dev/null; then
        deluser --system --quiet gaproxy
    fi

    # Delete upstart script
    if [[ -e /etc/init/google_auth_proxy.conf  ]]; then
      rm /etc/init/google_auth_proxy.conf
    fi

    if [[ -e /etc/init.d/google_auth_proxy  ]]; then
      rm /etc/init.d/google_auth_proxy
    fi

    # If dpkg deletes /opt like a jerk
    # http://stackoverflow.com/questions/13021002/my-deb-file-removes-opt
    if [[ ! -d /opt ]]; then
      mkdir /opt
    fi
    ;;
upgrade)
    echo "Upgrade, skipping clean up."
esac