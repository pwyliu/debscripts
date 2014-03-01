#!/bin/bash
set -e

# run forest run
if [ -x "/etc/init/etcd" ]; then
  service etcd start || exit $?
fi
