#!/bin/bash

# If no etcd user, create one
cat /etc/passwd | cut -d : -f 1 | grep etcd
if [[ $? -ne 0 ]]; then
  useradd -r --no-create-home --home-dir /opt/etcd --shell /bin/false etcd || exit $?
fi
