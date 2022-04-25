#!/bin/bash

set -ex

serverTitle=${1:-"generic"}
serverPort=${2:-8080}
otherServerPort=${2:-9090}
dependency=${3:-"dependency"}

scConfig=$(jq ".dnsConfig[0].hostName=\"${dependency}.my.corp\" | .ingressConfig[0].interceptPort=${serverPort} | @json" awsvpc_default_sc_conf.json)

overridesJson=$(jq ".containerOverrides[0].environment[0].value=${scConfig} | .containerOverrides[1].environment[0].value=\"${serverTitle}\" | .containerOverrides[1].environment[1].value=\"${serverPort}\" | .containerOverrides[1].environment[2].value=\"${otherServerPort}\"" task_overrides.json)

aws ecs run-task \
--task-definition sc-generic-server-awsvpc \
--cluster 3B6B8EC9-4640-41E3-8761-023F76B07364 \
--network-configuration "awsvpcConfiguration={subnets=[subnet-0aa34b0e7e4881fee],securityGroups=[sg-0604036f1bbb336ec]}" \
--overrides "${overridesJson}"