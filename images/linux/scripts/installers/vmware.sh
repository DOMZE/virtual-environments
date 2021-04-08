#!/bin/bash -e
################################################################################
##  File:  vmware.sh
##  Desc:  Installs VMWare tools
################################################################################

# Source the helpers for use with the script
source $HELPER_SCRIPTS/install.sh

## Install vmware tools
apt-get update
apt-get install open-vm-tools -y

invoke_tests "Tools" "VMWare"