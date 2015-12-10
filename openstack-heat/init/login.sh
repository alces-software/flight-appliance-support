#!/bin/bash
cat << EOF > /opt/clusterware/etc/config.yml
cluster:
  uuid: '%UUID%'
  token: '%TOKEN%'
  name: '%CWNAME%'
  role: 'master'
  tags:
    scheduler_roles: ':master:'
  quorum: 3
instance:
  users:
  - username: %CUNAME%
    uid: 509
    group: %CUNAME%
    gid: 509
    groups:
    - gridware
    - admins:388
    ssh_public_key: |
      ssh-rsa %CUKEY% openstack
EOF
