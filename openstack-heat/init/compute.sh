#!/bin/bash
cat << EOF > /opt/clusterware/etc/config.yml
cluster:
  uuid: '7b4249e8-637a-11e5-a343-7831c1c0e63c'
  token: 'YzYwN2E2OWItNjcwNS00'
  name: '%CWNAME%'
  role: 'slave'
  tags:
    scheduler_roles: ':compute:'
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
