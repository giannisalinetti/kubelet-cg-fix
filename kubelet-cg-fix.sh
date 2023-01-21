#!/bin/bash

# System constants
KUBEPODS_SLICE="kubepods.slice"
SYSTEMD_SLICE_MEM_CFG="/run/systemd/system/kubepods.slice.d/50-MemoryLimit.conf"

# Signal trap section
trap "{ echo 'Terminated with Ctrl+C'; exit 143; }" SIGINT
trap "{ echo 'Terminated with SIGKILL'; exit 137; }" SIGKILL

# Memory allocation variables
SYS_TOTAL_MEMORY=$(($(grep MemTotal /proc/meminfo | awk '{ print $2 }') * 1024))
# TODO: Make this variable dynamic from kubelet and system reserved memory info
RESERVED_MEMORY=999999999
EXPECTED_MEMORY_LIMIT_BYTES=$((${SYS_TOTAL_MEMORY} - ${RESERVED_MEMORY}))

# Main reconcile loop
echo "Starting kubepods.slice memory reconcile loop"
while true
do
    CURRENT_MEMORY_LIMIT_BYTES=$(grep "MemoryLimit" ${SYSTEMD_SLICE_MEM_CFG} | awk -F"=" '{ print $2 }')
    echo "$(date) - Reading kubepods.slice memory limit every 60s. Current value: ${CURRENT_MEMORY_LIMIT_BYTES}"
    if [ ${CURRENT_MEMORY_LIMIT_BYTES} -ne ${EXPECTED_MEMORY_LIMIT_BYTES} ]; then
        echo "$(date) - Reconciling slice memory limits to expected value of ${EXPECTED_MEMORY_LIMIT_BYTES}"
        systemctl set-property ${KUBEPODS_SLICE} MemoryLimit=${EXPECTED_MEMORY_LIMIT_BYTES}
        if [ $? -ne 0 ]; then
            echo "$(date) - Error reconciling memory limit for kubepods.slice"
        fi
        echo "$(date) - Restarting kubepods.slice unit"
        systemctl daemon-reload && systemctl restart kubepods.slice
    fi
    sleep 60
done

