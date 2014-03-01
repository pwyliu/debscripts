#!/bin/bash
set -e

# shut this bitch down
if [ -x "/etc/init/etcd" ]; then
  service etcd stop || exit $?
fi
