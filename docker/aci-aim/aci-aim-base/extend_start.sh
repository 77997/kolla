#!/bin/bash

if [[ ! -d "/var/log/aim" ]]; then
    mkdir -p /var/log/aim
fi

if [[ ! -d "/var/lib/aim" ]]; then
    mkdir -p /var/lib/aim
fi

# Bootstrap and exit if KOLLA_BOOTSTRAP variable is set. This catches all cases
# of the KOLLA_BOOTSTRAP variable being set, including empty.
if [[ "${!KOLLA_BOOTSTRAP[@]}" ]]; then
    aimctl --config-file /etc/aim/aim.conf config replace
    exit 0
fi
