#!/bin/bash

# run forest run
if [[ -f "/etc/init/etcd.conf" ]]; then
  service etcd start || exit $?
fi
