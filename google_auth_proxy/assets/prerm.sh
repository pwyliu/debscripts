#!/bin/bash

if pidof "google_auth_proxy" > /dev/null; then
  service google_auth_proxy stop || exit $?
fi
