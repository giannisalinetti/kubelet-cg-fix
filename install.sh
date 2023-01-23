#!/bin/bash

SCRIPT_NAME=kubelet-cg-fix.sh
UNIT_NAME=kubelet-cg-fix.service
SYSTEMD_PATH=/etc/systemd/system/

# Update this value to adjust custom reserved ratio
CUSTOM_RESERVED_RATIO=20

# Ensure /usr/local/bin exists
if [ ! -d /usr/local/bin ]; then
    mkdir /usr/local/bin
fi

# Copy script to /usr/local/bin
cp ${SCRIPT_NAME} /usr/local/bin
chown root:root /usr/local/bin/${SCRIPT_NAME}
chmod 755 /usr/local/bin/${SCRIPT_NAME}

# Install systemd service
cp ${UNIT_NAME} /tmp && sed -i "s/{{ memory_reserved_ratio }}/${CUSTOM_RESERVED_RATIO}/" /tmp/${UNIT_NAME} 
cp /tmp/${UNIT_NAME} ${SYSTEMD_PATH} && systemctl daemon-reload

# Start and enable systemd service
systemctl enable --now ${UNIT_NAME}
if [ $? -ne 0 ]; then
    echo "$(date) - Error starting ${UNIT_NAME} systemd service"
    exit 1
fi

# Wait until service is active
while ! systemctl is-active ${UNIT_NAME} > /dev/null
do
    sleep 1
done

exit 0

