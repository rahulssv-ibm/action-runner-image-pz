#!/bin/bash -e
################################################################################
##  File:  configure-apt-sources.sh
##  Desc:  Configure apt sources with failover from Azure to Ubuntu archives.
################################################################################

# shellcheck disable=SC1091
source "$HELPER_SCRIPTS"/os.sh

touch /etc/apt/apt-mirrors.txt

printf "http://azure.archive.ubuntu.com/ubuntu/\tpriority:1\n" | tee -a /etc/apt/apt-mirrors.txt
printf "https://archive.ubuntu.com/ubuntu/\tpriority:2\n" | tee -a /etc/apt/apt-mirrors.txt
printf "https://security.ubuntu.com/ubuntu/\tpriority:3\n" | tee -a /etc/apt/apt-mirrors.txt

# ponytail: sed -i renames the file, failing on LXD /etc (overlayfs EBUSY); tee back to same inode instead.
sed_inplace() { local f=$2; echo "$(sed "$1" "$f")" | tee "$f" > /dev/null; }

if is_ubuntu24; then
    sed_inplace 's|http://azure\.archive\.ubuntu\.com/ubuntu/|mirror+file:/etc/apt/apt-mirrors.txt|' /etc/apt/sources.list.d/ubuntu.sources

    # Apt changes to survive Cloud Init
    cp -f /etc/apt/sources.list.d/ubuntu.sources  /etc/cloud/templates/sources.list.ubuntu.deb822.tmpl
else
    sed_inplace 's|http://azure\.archive\.ubuntu\.com/ubuntu/|mirror+file:/etc/apt/apt-mirrors.txt|' /etc/apt/sources.list

    # Apt changes to survive Cloud Init
    cp -f /etc/apt/sources.list /etc/cloud/templates/sources.list.ubuntu.tmpl
fi
