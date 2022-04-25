#!/bin/bash

set -ex

ingress_port=$(echo ${SC_CONFIG} | jq -c '.ingressConfig | .[] | select (.listenerName == "ingress_listener") | .listenerPort ')

if [[ "${ingress_port}" == "null" || "${ingress_port}" == "0" ]]
then
  ingress_port=$(echo ${listener_port_mapping} | jq -c '.ingress_listener')
fi


egress_port=$(echo ${listener_port_mapping} | jq -c '.egress_listener')

app_port=$(echo ${SC_CONFIG} | jq -c '.ingressConfig | .[] | select (.listenerName == "ingress_listener") | .interceptPort ')
if [ -z "$app_port" ]
then
  app_port=${SC_APP_PORT}
fi

_SC_INGRESS_PORT_=${ingress_port:-15000}
_SC_EGRESS_PORT_=${egress_port:-30000}
_SC_APP_PORT_=${app_port:-8080}
_SC_REMOTE_PORT_=${SC_REMOTE_PORT:-7575}

sed -i "s/SC_INGRESS_PORT/${_SC_INGRESS_PORT_}/g" "/etc/envoy/lds_config.yaml"
sed -i "s/SC_EGRESS_PORT/${_SC_EGRESS_PORT_}/g" "/etc/envoy/lds_config.yaml"
sed -i "s/SC_APP_PORT/${_SC_APP_PORT_}/g" "/etc/envoy/local_eds.yaml"
sed -i "s/SC_REMOTE_PORT/${_SC_REMOTE_PORT_}/g" "/etc/envoy/remote_eds.yaml"


/usr/bin/envoy -c /etc/envoy/envoy.yaml -l debug