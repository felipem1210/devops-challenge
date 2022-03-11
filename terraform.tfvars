# Required parameters
aws_region  = "us-east-1"
name        = "organization"
environment = "dev"
# VPC parameters
cidr_block      = "10.0.0.0/16"
azs             = ["us-east-1a","us-east-1b","us-east-1c"]
private_subnets = ["10.0.0.0/19", "10.0.32.0/19", "10.0.64.0/19"]
public_subnets  = ["10.0.128.0/19", "10.0.160.0/19", "10.0.192.0/19"]
# EC2 parameters
max_asg_size  = 3
min_asg_size  = 1
key_pair_name = ""
# Security group for EC2 instance
ec2_ingress_rules = [
  {
    cidr_block = []
    port = 80
  },
  {
    cidr_block = ["10.0.0.0/16"]
    port = 22
  }
]
# S3
s3_bucket_name = "organization-awesome-challenge-bucket"
s3_object = "test.txt"

custom_tags = {
  "Env" = "dev"
}