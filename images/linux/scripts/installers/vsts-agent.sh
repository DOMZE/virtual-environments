#!/bin/bash -e
################################################################################
##  File:  vsts-agent.sh
##  Desc:  Installs the VSTS (Azure DevOps) agent
################################################################################

# Source the helpers for use with the script
source $HELPER_SCRIPTS/install.sh

# Install Alibaba Cloud CLI
VSTS_ASSETS_URL=$(curl -s https://api.github.com/repos/microsoft/azure-pipelines-agent/releases/latest | jq -r '.assets[].browser_download_url')
download_with_retries $VSTS_ASSETS_URL "/tmp"
URL=$(cat /tmp/assets.json | jq -r '.[] | select((.name | startswith("vsts-agent-linux")) and .platform == "linux-x64") | .downloadUrl')
download_with_retries $URL "/tmp"
mkdir /agent
tar -xzf /tmp/vsts-agent-linux-*.tar.gz --directory /agent