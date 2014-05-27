#!/bin/bash

# If etcd user, delete
cat /etc/passwd | cut -d : -f 1 | grep redoctober
if [[ $? -eq 0 ]]; then
  userdel redoctober || exit $?
fi

# Delete upstart script
if [[ -e /etc/init/redoctober.conf  ]]; then
  rm /etc/init/redoctober.conf || exit $?
fi

if [[ -e /etc/init.d/redoctober  ]]; then
  rm /etc/init.d/redoctober || exit $?
fi

# If dpkg deletes /opt like a jerk
# http://stackoverflow.com/questions/13021002/my-deb-file-removes-opt
if [[ ! -d /opt ]]; then
  mkdir /opt
fi