# Required parameters
aws_region  = "us-east-1"
name        = "bestseller"
environment = "dev"
# VPC parameters
cidr_block      = "10.10.0.0/16"
azs             = ["us-east-1a","us-east-1b","us-east-1c"]
private_subnets = ["10.0.0.0/19", "10.0.32.0/19", "10.0.64.0/19"]
public_subnets  = ["10.0.128.0/19", "10.0.160.0/19", "10.0.192.0/19"]
# EC2 parameters
max_asg_size = 2
min_asg_size = 1
# Security group for EC2 instance
ec2_ingress_rules = [{
  cidr_block = []
  port = 80
}]