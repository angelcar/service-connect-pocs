#!/bin/bash

set -ex

pingOrPong=${1:-ping}

other=""
if [ "${pingOrPong}" == "ping" ]; then other="pong"; fi
if [ "${pingOrPong}" == "pong" ]; then other="ping"; fi

scConfig=$(jq ".dnsConfig[0].hostname=\"${other}.my.corp\" | @json" awsvpc_default_sc_conf.json)

overridesJson=$(jq -c ".containerOverrides[0].environment[0].value=${scConfig} | .containerOverrides[1].environment[0].value=\"${pingOrPong}\"" task_overrides.json)

aws ecs run-task \
--task-definition sc-pingpong-awsvpc \
--cluster 3B6B8EC9-4640-41E3-8761-023F76B07364 \
--network-configuration "awsvpcConfiguration={subnets=[subnet-0aa34b0e7e4881fee],securityGroups=[sg-0604036f1bbb336ec]}" \
--overrides "${overridesJson}"