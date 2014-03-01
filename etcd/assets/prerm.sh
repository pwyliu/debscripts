#!/bin/bash
set -e

# shut this bitch down
if [[ -f "/etc/init/etcd.conf" ]]; then
  service etcd stop || exit $?
fi
