#!/bin/bash -l
# Compute group name should be fed in through cloud-init or other means
computegroup="alces1-ComputeGroup-13L5PPGC0IG6V"
# AWS requires timestamp in the following format
timestamp=$(date +'%Y-%m-%d'T'%T'.000Z)
queued=$(qstat -u \* | awk 'NR > 2{print $5}' | wc -l)
/opt/clusterware/opt/aws/bin/aws cloudwatch put-metric-data --region "eu-west-1" --metric-name Queued --namespace "ALCES-SGE" --dimensions "AutoScalingGroupName=${computegroup}" --value $queued --timestamp $timestamp
