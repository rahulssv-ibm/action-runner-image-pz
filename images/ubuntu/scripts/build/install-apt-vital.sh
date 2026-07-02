#!/bin/bash -e
################################################################################
##  File:  install-apt-vital.sh
##  Desc:  Install vital command line utilities
################################################################################

# Source the helpers for use with the script
# shellcheck disable=SC1091
source "$HELPER_SCRIPTS"/install.sh

# apt-utils must be present before any other package triggers debconf configuration
install_dpkgs apt-utils

vital_packages=$(get_toolset_value .apt.vital_packages[])
install_dpkgs --no-install-recommends "$vital_packages"
