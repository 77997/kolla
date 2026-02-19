#!/bin/bash

# ACI AIM base extend_start.sh
# This script is sourced by the kolla_start script to perform
# any necessary setup before starting the AIM services.

if [[ ! -d "/var/log/aim" ]]; then
    mkdir -p /var/log/aim
fi

if [[ ! -d "/var/lib/aim" ]]; then
    mkdir -p /var/lib/aim
fi
