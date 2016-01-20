#!/bin/bash
cat << EOF > /opt/clusterware/etc/config.yml
cluster:
  uuid: '%UUID%'
  token: '%TOKEN%'
  name: '%CWNAME%'
  role: 'master'
  tags:
    scheduler_roles: ':master:'
    storage_roles: ':master:'
  quorum: 3
  gridware:
    depots:
    - name: %INSTALL%
      url: https://s3-eu-west-1.amazonaws.com/packages.alces-software.com/depots/%INSTALL%
EOF
