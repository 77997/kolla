#!/bin/bash

# OpFlex agent extend_start.sh
# This script is sourced by the kolla_start script to perform
# any necessary setup before starting the OpFlex agent.

if [[ ! -d "/var/log/opflex-agent" ]]; then
    mkdir -p /var/log/opflex-agent
fi

if [[ ! -d "/var/lib/opflex-agent" ]]; then
    mkdir -p /var/lib/opflex-agent
fi

# Ensure OVS is accessible
if [[ -S "/var/run/openvswitch/db.sock" ]]; then
    echo "OVS socket found"
else
    echo "WARNING: OVS socket not found at /var/run/openvswitch/db.sock"
fi
