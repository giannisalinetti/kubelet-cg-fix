#!/bin/bash

# Signal trap section
trap "{ echo 'Terminated with Ctrl+C'; exit 143; }" SIGINT
trap "{ echo 'Terminated with SIGKILL'; exit 137; }" SIGKILL

# Usage function
usage() { echo "Usage: $0 [-r MEMORY_RESERVED_RATIO]"; exit 1; }

# Flags parsing
while getopts ":hr:" flag
do
    case "${flag}" in
        r) MEMORY_RESERVED_RATIO=${OPTARG}
           ;;
        h) usage
           ;;
        *) usage
           ;;
    esac
done

# System constants
KUBEPODS_SLICE="kubepods.slice"
SYSTEMD_SLICE_MEM_CFG="/run/systemd/system/kubepods.slice.d/50-MemoryLimit.conf"

# Wait for kubepods.slice to become active
echo "$(date) - Waiting for kubepods.slice to become active"
while ! systemctl is-active ${KUBEPODS_SLICE} > /dev/null; do
    sleep 5
done
    
# Memory allocation variables
SYS_TOTAL_MEMORY=$(($(grep MemTotal /proc/meminfo | awk '{ print $2 }') * 1024))
# TODO: Make this variable dynamic from kubelet and system reserved memory extracted informations
# Currently we override using a pattern based on the 20% of the overall memory or custom value passed by cmdline
RESERVED_MEMORY=$((SYS_TOTAL_MEMORY / 100 * ${MEMORY_RESERVED_RATIO}))
EXPECTED_MEMORY_LIMIT_BYTES=$((${SYS_TOTAL_MEMORY} - ${RESERVED_MEMORY}))

# Set MEMORY_RESERVED_RATIO to 20 if no custom argument is passed by user
if [ -z $MEMORY_RESERVED_RATIO ]; then
    MEMORY_RESERVED_RATIO=20
fi

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

