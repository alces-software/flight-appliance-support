#Monitoring scheduler load and maintaining autoscaling group
Using custom CloudWatch metrics enables us to export the current scheduler workload status, in this case - the number of jobs queued over a specified period. 

The number of jobs queued can be used to either scale-up or scale-down the auto-scaling group(s) associated with a particular environment. 

##Providing custom metric data
The master node is provided an IAM role, which gives it sufficient access to write metric data to CloudWatch. The below script exports the current number of jobs waiting in the queue to CloudWatch. 

```bash
#!/bin/bash -l
# Compute group name should be fed in through cloud-init or other means
computegroup="alces1-ComputeGroup-13L5PPGC0IG6V"
# AWS requires timestamp in the following format
timestamp=$(date +'%Y-%m-%d'T'%T'.000Z)
queued=$(qstat -u \* | awk 'NR > 2{print $5}' | wc -l)
/opt/clusterware/opt/aws/bin/aws cloudwatch put-metric-data --metric-name Queued --namespace "ALCES-SGE" --dimensions "AutoScalingGroupName=${computegroup}" --value $queued --timestamp $timestamp
```

The above should be added as a cron job. 
