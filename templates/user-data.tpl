#!/bin/bash
# Script to install apache and necessary software

set -e
apt-get update -y
apt-get install nginx -y
snap install aws-cli --classic
AWS_INSTANCE_ID=`curl -s http://169.254.169.254/latest/meta-data/instance-id`
OBJECT=`aws s3api list-objects --bucket ${bucket_name}`
printf "Hello World!, from $AWS_INSTANCE_ID instance \n
      Checking if instance can read object from s3 bucket \n
      $OBJECT" > /var/www/html/index.html
