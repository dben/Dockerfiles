# How to set up traefik
_Note that there may be some redundant labels / env vars_

#### AWS Elastic File System
1. Create a EFS drive.
2. Attach a security group to EFS 

#### AWS Elastic Container Service
3. Create an ECS cluster

#### AWS Elastic Cloud Compute
4. Mount the EFS drive to a disposable EC2 instance that allows all connections from the EFS security group
   1. Install the nfs client on your EC2 instance
      1. On an Amazon Linux, Red Hat Enterprise Linux, or SuSE Linux instance: `sudo yum install -y nfs-utils`
      2. On an Ubuntu instance: `sudo apt-get install nfs-common`
   2. Create a new directory on your EC2 instance, such as `efs` by running `mkdir efs`
   3. Mount your file system using the DNS name
      `sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2 XXXXXX.efs.us-east-2.amazonaws.com:/ efs`
5. Touch acme.json
6. Throw away EC2 instance
7. Create a launch configuration from the latest ECS AMI. Should have the following snippet as user data.
   1. "ZZZZZZ" should be replaced by the ECS Cluster name from the cluster created in step 6.
   2. "XXXXXX" should be replaced by the first part of the EFS DNS name from the file system created in step 1.

```
#!/bin/bash
echo ECS_CLUSTER=ZZZZZZ >> /etc/ecs/ecs.config

yum install -y nfs-utils
mkdir /efs
mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2 XXXXXX.efs.us-east-1.amazonaws.com:/ /efs

service docker restart
start ecs
```
 
8. Create an auto scaling group - peg the number of instances for now (no scaling) 

#### Docker Build
9. `chmod 555 docker-entrypoint.sh`
   1. If you need to run the `docker` command in your `ecs push` step, add this line immediately before the `docker build` line so that permissions are set correctly to let everything work as expected.

#### AWS Elastic Container Service
10. Create a new docker repo for traefik, or use https://hub.docker.com/r/dben0/traefik-ecs/
11. Create a new traefik task:
    1. set the command to some variation of: "--api,--ping,--ping.entrypoint=http,--ecs.clusters=ZZZZZZ,--ecs.exposedbydefault=false,--loglevel=DEBUG"
    2. mount the volume /efs/acme.json to /acme.json
    3. set the environment variables
    4. set the labels on your container (feel free to go wild!) 
       https://github.com/containous/traefik/blob/master/docs/configuration/backends/docker.md#on-containers

###### Environment Variables
```
AWS_ACCESS_KEY_ID       AAAAAA
AWS_REGION              us-east-1
AWS_SECRET_ACCESS_KEY	BBBBBBB
CLUSTER_HOST            ZZZZZZ
DOMAIN	               ROOT.DOMAIN
ENVIRONMENT	            staging|prod|dev (I used staging)
```

###### Labels
```
traefik.frontend.rule	               Host:YOUR.DOMAIN.NAME
traefik.enable	                        true
traefik.backend	                     UNIQUE-NAME
traefik.frontend.redirect.entryPoint   https (optional)
traefik.frontend.redirect.permanent    true (optional)
```

12. remove the host port on your container, and launch it in a service. Traefik will scale across containers on any instance 
  
#### AWS Route53
13. Update route 53 to round robin all autoscaling containers 
  
#### AWS Lambda
14. Future task: lambda to update route 53 when autoscaling occurs. 

#### AWS Elastic Container Service
15. Future task: switch to using a container task role instead of a key
