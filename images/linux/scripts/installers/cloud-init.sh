#!/bin/bash -e
################################################################################
##  File:  cloud-init.sh
##  Desc:  Installs cloud-init
################################################################################

# Install cloud-init
apt-get update
apt-get install cloud-init -y
