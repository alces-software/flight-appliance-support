#!/bin/bash
cat << EOF > /opt/clusterware/etc/config.yml
cluster:
  uuid: '%UUID%'
  token: '%TOKEN%'
  name: '%CWNAME%'
  role: 'slave'
  tags:
    scheduler_roles: ':compute:'
  quorum: 3
EOF
