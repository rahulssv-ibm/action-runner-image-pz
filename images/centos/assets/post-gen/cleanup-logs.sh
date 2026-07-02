#!/bin/bash

# journalctl — binary exists even in containers, but journal socket may not
if command -v journalctl > /dev/null 2>&1 && journalctl --no-pager -n0 > /dev/null 2>&1; then
    journalctl --rotate
    journalctl --vacuum-time=1s
fi

# delete all .gz and rotated file
find /var/log -type f -regex ".*\.gz$" -delete
find /var/log -type f -regex ".*\.[0-9]$" -delete

# wipe log files
find /var/log/ -type f -exec cp /dev/null {} \;