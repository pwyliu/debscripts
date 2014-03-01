#!/bin/bash

# run forest run
if [ -f "/etc/init/etcd" ]; then
  service etcd start || exit $?
fi
