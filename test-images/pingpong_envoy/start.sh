#!/bin/bash

_SC_INGRESS_PORT_=${SC_INGRESS_PORT:-15000}
_SC_EGRESS_PORT_=${SC_EGRESS_PORT:-30000}

sed -i "s/SC_INGRESS_PORT/${_SC_INGRESS_PORT_}/g" "/etc/envoy/lds_config.yaml"
sed -i "s/SC_EGRESS_PORT/${_SC_EGRESS_PORT_}/g" "/etc/envoy/lds_config.yaml"

/usr/bin/envoy -c /etc/envoy/envoy.yaml -l debug