#!/bin/bash

SCRIPT_NAME=kubelet-cg-fix.sh
UNIT_NAME=kubelet-cg-fix.service
SYSTEMD_PATH=/etc/systemd/system/

# Ensure /usr/local/bin exists
if [ -d /usr/local/bin ]; then
    mkdir /usr/local/bin
fi

# Copy script to /usr/local/bin
cp ${SCRIPT_NAME} /usr/local/bin

# Install systemd service
cp ${UNIT_NAME} ${SYSTEMD_PATH} && systemctl daemon-reload

# Start and enable systemd service
systemctl enable --now ${UNIT_NAME}
if [ $? -ne 0 ]; then
    echo "$(date) - Error starting ${UNIT_NAME} systemd service"
    exit 1
fi
