#!/bin/bash

# Replace $HOME with the default user's home directory for environmental variables related to the default user home directory

homeDir=$(cut -d: -f6 /etc/passwd | tail -1)
# ponytail: sed -i renames the file, failing on bind-mounts/overlayfs; write back through tee instead.
content=$(sed "s|\$HOME|$homeDir|g" /etc/environment)
echo "$content" | tee /etc/environment > /dev/null