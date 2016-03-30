#!/bin/bash -l
instanceid=$(curl http://169.254.169.254/1.0/meta-data/instance-id)
clustername=$(cat /opt/clusterware/etc/config.yml | grep name | awk '{print $2}')
group=$(/opt/clusterware/opt/aws/bin/aws --region "eu-west-1" autoscaling describe-auto-scaling-groups | grep AutoScalingGroupName | grep ${clustername} | awk '{print $2}' | tr -d '"' | tr -d ',')
currentcap=$(/opt/clusterware/opt/aws/bin/aws --region "eu-west-1" autoscaling describe-auto-scaling-groups --auto-scaling-group-names ${group} | grep DesiredCapacity | awk '{print $2}' | tr -d ',')
desired=$((currentcap -1))
jobs=$(ls /var/spool/gridscheduler/execd/${HOSTNAME}/active_jobs/ | wc -l)
if [ "$jobs" == 0 ]; then
  /opt/clusterware/opt/aws/bin/aws --region "eu-west-1" \
  autoscaling update-auto-scaling-group \
  --auto-scaling-group-name ${group} \
  --desired-capacity ${desired}
  halt -f
fi
