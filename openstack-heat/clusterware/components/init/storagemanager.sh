#!/bin/bash
cat << EOF > /opt/clusterware/etc/config.yml
cluster:
  uuid: '%UUID%'
  token: '%TOKEN%'
  name: '%CWNAME%'
  role: 'appliance'
  tags:
    appliance_roles: ':storage:'
  quorum: 3
EOF
