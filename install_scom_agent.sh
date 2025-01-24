#!/bin/bash

# install_scom_agent.sh

SCOM_SERVER="scom-server"
AGENT_DOWNLOAD_URL="https://path-to-linux-agent.tar.gz"
INSTALL_DIR="/opt/scom-agent"

echo "Downloading and installing SCOM Agent for Linux..."

# Download the agent package
mkdir -p $INSTALL_DIR
curl -o $INSTALL_DIR/scom-agent.tar.gz $AGENT_DOWNLOAD_URL

# Extract and install
tar -xvzf $INSTALL_DIR/scom-agent.tar.gz -C $INSTALL_DIR
cd $INSTALL_DIR
sudo ./install --server $SCOM_SERVER --agent-user scomuser --agent-group scomgroup

echo "SCOM Agent installation on Linux is complete."
