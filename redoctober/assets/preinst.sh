#!/bin/bash

# If no user, create one
cat /etc/passwd | cut -d : -f 1 | grep redoctober
if [[ $? -ne 0 ]]; then
  useradd -r --no-create-home --home-dir /opt/redoctober --shell /bin/false redoctober || exit $?
fi
