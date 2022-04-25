#!/bin/bash


ingress_port=$(echo ${SC_CONFIG} | jq -c '.ingressConfig | .[] | select (.listenerName == "ingress_listener") | .ListenerPort ')

if [ -z "$ingress_port" ]
then
  ingress_port=$(echo ${listener_port_mapping} | jq -c '.[] | select(.ingress_listener) | .ingress_listener')
fi


egress_port=$(echo ${listener_port_mapping} | jq -c '.[] | select(.egress_listener) | .egress_listener')

_SC_INGRESS_PORT_=${ingress_port:-15000}
_SC_EGRESS_PORT_=${egress_port:-30000}

sed -i "s/SC_INGRESS_PORT/${_SC_INGRESS_PORT_}/g" "/etc/envoy/lds_config.yaml"
sed -i "s/SC_EGRESS_PORT/${_SC_EGRESS_PORT_}/g" "/etc/envoy/lds_config.yaml"

/usr/bin/envoy -c /etc/envoy/envoy.yaml -l debug