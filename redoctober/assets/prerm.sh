#!/bin/bash

# shut this bitch down
if pidof "redoctober" > /dev/null; then
  service redoctober stop || exit $?
fi