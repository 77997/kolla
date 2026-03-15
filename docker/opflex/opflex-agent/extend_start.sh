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

# Create droplog config directory watched by the C++ agent
mkdir -p /var/lib/opflex-agent-ovs/droplog

# If packet logging is enabled, wrap the C++ opflex_agent binary
# so it starts with --drop_log_syslog for per-SG permit/deny logging
if [[ "${OPFLEX_ENABLE_DROP_LOG}" == "true" ]]; then
    REAL_BINARY="/usr/local/bin/opflex_agent"
    if [[ -x "${REAL_BINARY}" && ! -f "${REAL_BINARY}.real" ]]; then
        mv "${REAL_BINARY}" "${REAL_BINARY}.real"
        cat > "${REAL_BINARY}" <<'WRAPPER'
#!/bin/bash
exec /usr/local/bin/opflex_agent.real --drop_log_syslog "$@"
WRAPPER
        chmod +x "${REAL_BINARY}"
    fi

    # Deploy the drop-log renderer config if present in kolla config
    DROPLOG_CONF="/var/lib/kolla/config_files/opflex_droplog.conf"
    if [[ -f "${DROPLOG_CONF}" ]]; then
        mkdir -p /etc/opflex-agent-ovs/conf.d
        cp "${DROPLOG_CONF}" /etc/opflex-agent-ovs/conf.d/droplog.conf
    fi
fi
