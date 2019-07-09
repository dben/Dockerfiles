# How to set up traefik

#### AWS Elastic File System
1. Create a EFS drive.
2. Attach a security group to EFS 

#### AWS Elastic Container Service
3. Create an ECS cluster
4. Generate an AWS ECS task role with the following permissions. You will use this role for the Traefik task created later:
```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "TraefikECSReadAccess",
            "Effect": "Allow",
            "Action": [
                "ecs:ListClusters",
                "ecs:DescribeClusters",
                "ecs:ListTasks",
                "ecs:DescribeTasks",
                "ecs:DescribeContainerInstances",
                "ecs:DescribeTaskDefinition",
                "ec2:DescribeInstances"
            ],
            "Resource": [
                "*"
            ]
        }
    ]
}

```

#### AWS Elastic Cloud Compute
5. Create a launch configuration from the latest ECS AMI. Should have the following snippet as user data.
   1. <ECS-CLUSER-NAME> should be replaced by the ECS Cluster name from the cluster created in step 3.
   2. <EFS-URL> should be replaced by the first part of the EFS DNS name from the file system created in step 1.

```
#!/bin/bash
echo ECS_CLUSTER=<ECS-CLUSER-NAME> >> /etc/ecs/ecs.config

yum install -y nfs-utils
mkdir /efs
mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2 <EFS-URL>.amazonaws.com:/ /efs

service docker restart
start ecs
```
6. Ensure the instance has an IAM role with the AmazonEC2ContainerServiceforEC2Role policy

7. Create an auto scaling group - peg the number of instances for now (no scaling) 

#### AWS Elastic Container Service
7. Create a new ECS task for traefik
   1. Use dben0/traefik-ecs for the latest version of this repository
   2. Or, to build your own version, run `chmod 555 docker-entrypoint.sh` to ensure permissions are correct, and then build and push to your own repository
   3. Set a soft limit on the memory od between 100-500MB
   4. Pass through ports 80, 8080, and 443
   5. Set the command to some variation of:
    ```
      --api,--ping,--ping.entrypoint=http, --loglevel=DEBUG
    ```
    `  --api:              enables traefik management api`
    
    `  --ping:             sets up a /ping endpoint on containers to use for health checks`
    
    `  --ping.entrypoint:  choose between http and https for the ping endpoint`
    
    `  --loglevel:         sets log level`

   6. mount the volume /efs/acme.json to /acme.json
   7. set the environment variables
    ```
    AWS_ACCESS_KEY_ID	<AWS-ACCESS-KEY>
    AWS_REGION	<AWS-REGION (us-east-1)>
    AWS_SECRET_ACCESS_KEY	<AWS-SECRET>
    CLUSTER_HOST	<ECS-CLUSER-NAME>
    DOMAIN	TLD to use by default
    ENVIRONMENT	default subdomain name
    EMAIL letsencrypt email address
    ```
   8. set the labels on your container (feel free to go wild!) 
       https://github.com/containous/traefik/blob/master/docs/configuration/backends/docker.md#on-containers
    ```
    traefik.frontend.rule	Host:<YOUR.TRAEFIK.URL> (optional)
    traefik.enable	true
    traefik.port	8080    (lock this port behind a firewall)
    ```

##### Application containers

8. remove the host port on your container, and launch it in a service. Traefik will scale across containers on any instance.
9. Add the following labels to your application task:

```
traefik.frontend.rule	Host:<YOUR.DOMAIN.NAME>  (optional)
traefik.enable	true
traefik.backend	<UNIQUE-NAME> (optional, shows in the admin)
traefik.frontend.redirect.entryPoint    https (optional)
traefik.frontend.redirect.permanent     true (optional)
```
  

#### AWS Route53
10. Update route 53 to round robin all autoscaling containers
 
#### AWS Lambda
11. Future task: lambda to update route 53 when autoscaling occurs. 
https://gist.github.com/ambakshi/8d2276af73cc896cab5f
