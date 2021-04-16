#!/bin/bash -e
################################################################################
##  File:  cloud-init.sh
##  Desc:  Installs cloud-init
################################################################################

# Install cloud-init that leverages guestinfo
apt-get update
apt install cloud-init -y

# Enabling vSphere customization to call cloud-init - reference: https://github.com/vmware/open-vm-tools/issues/240#issuecomment-395652692
echo "disable_vmware_customization: false" >> /etc/cloud/cloud.cfg
echo "datasource_list: [ OVF ]" | tee /etc/cloud/cloud.cfg.d/99-DataSourceOVF.cfg

# Clear the machine-id to ensure the new/cloned VMs get unique IDs and IP addresses. reference: https://unix.stackexchange.com/a/419322/24359
echo -n > /etc/machine-id

systemctl enable cloud-init-local.service
systemctl enable cloud-init.service
systemctl enable cloud-config.service
systemctl enable cloud-final.service

# Reset Cloud-init state. reference: https://stackoverflow.com/questions/57564641/openstack-Packer-cloud-init
cloud-init clean -s -l