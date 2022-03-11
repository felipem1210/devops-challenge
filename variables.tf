# ----------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# ----------------------------------------------------------------------------------------------------------------------

variable "aws_region" {
  description = "The AWS Region where this resources will exist."
  type        = string
}

variable "name" {
  description = "Conventional name for all the resources. Can be the customer or company name."
  type        = string
}

variable "environment" {
  description = "The environment for resources."
  type        = string
}


# ----------------------------------------------------------------------------------------------------------------------
# VPC PARAMETERS
# ----------------------------------------------------------------------------------------------------------------------

variable "azs" {
  description = "A list of availability zones names or ids in the region"
  type        = list(string)
  default     = []
}


variable "public_subnets" {
  description = "A list of public subnets inside the VPC"
  type        = list(string)
  default     = []
}

variable "private_subnets" {
  description = "A list of private subnets inside the VPC"
  type        = list(string)
  default     = []
}

variable "cidr_block" {
  description = "The IP address range of the VPC in CIDR notation. A prefix of /16 is recommended. Do not use a prefix higher than /27. Examples include '10.100.0.0/16', '10.200.0.0/16', etc."
  type        = string
}

variable "instance_tenancy" {
  description = "A tenancy option for instances launched into the VPC"
  type        = string
  default     = "default"
}

variable "custom_tags" {
  description = "A map of tags to apply to the VPC, Subnets, Route Tables, and Internet Gateway. The key is the tag name and the value is the tag value. Note that the tag 'Name' is automatically added by this module but may be optionally overwritten by this variable."
  type        = map(string)
  default     = {}
}

variable "vpc_custom_tags" {
  description = "A map of tags to apply just to the VPC itself, but not any of the other resources. The key is the tag name and the value is the tag value. Note that tags defined here will override tags defined as custom_tags in case of conflict."
  type        = map(string)
  default     = {}
}

variable "public_subnet_custom_tags" {
  description = "A map of tags to apply to the public Subnet, on top of the custom_tags. The key is the tag name and the value is the tag value. Note that tags defined here will override tags defined as custom_tags in case of conflict."
  type        = map(string)
  default     = {}
}

variable "private_subnet_custom_tags" {
  description = "A map of tags to apply to the private-app Subnet, on top of the custom_tags. The key is the tag name and the value is the tag value. Note that tags defined here will override tags defined as custom_tags in case of conflict."
  type        = map(string)
  default     = {}
}


variable "map_public_ip_on_launch" {
  description = "Specify true to indicate that instances launched into the public subnet should be assigned a public IP address (versus a private IP address)"
  type        = bool
  default     = true
}

variable "subnets_calculator_enable" {
  type = bool
  default = true
}

# ----------------------------------------------------------------------------------------------------------------------
# EC2 PARAMETERS
# ----------------------------------------------------------------------------------------------------------------------

variable "max_asg_size" {
  description = "The maximum size of the Auto Scaling Group."
  type        = number
}

variable "min_asg_size" {
  description = "The minimum size of the Auto Scaling Group."
  type        = number
}

variable "asg_health_check_grace_period" {
  description = "(Optional, Default: 300) Time (in seconds) after instance comes into service before checking health."
  type        = number
  default     = 300
}

variable "ami_id" {
  description = "The AMI from which to launch the instance."
  type        = string
  default     = ""
}

variable "key_pair_name" {
  description = "The key pair name to connect through ssh"
  type        = string
  default     = ""
}

variable "instance_type" {
  description = "The type of the instance"
  type        = string
  default     = "t2.micro"
}

variable "asg_health_check_type" {
  description = "(Optional) EC2 or ELB. Controls how health checking is done."
  type        = string
  default     = "ELB"
}

variable "asg_desired_capacity" {
  description = "(Optional) The number of Amazon EC2 instances that should be running in the group."
  type        = number
  default     = "1"
}

variable "asg_force_delete" {
  description = " (Optional) Allows deleting the Auto Scaling Group without waiting for all instances in the pool to terminate. You can force an Auto Scaling Group to delete even if it's in the process of scaling a resource. Normally, Terraform drains all the instances before deleting the group. This bypasses that behavior and potentially leaves resources dangling."
  type        = bool
  default     = false
}

variable "ec2_ingress_rules" {
  type = list(object({
    port       = number
    cidr_block = list(string)
  }))
  description = "Specify the port range, and CIDRs for security group ingress rules."
}

variable "cpu_maximum_value_scale_up" {
  description = "The maximum value of cpu used by EC2 instances to scale up a new instance in ASG"
  type        = string
  default     = "80"
}

variable "cpu_minimum_value_scale_down" {
  description = "The minimum value of cpu used by EC2 instances to scale down instance in ASG"
  type        = string
  default     = "60"
}

# ----------------------------------------------------------------------------------------------------------------------
# S3 PARAMETERS
# ----------------------------------------------------------------------------------------------------------------------

variable "s3_bucket_name" {
  description = "The name of the s3 bucket to create"
  type        = string
}
variable "s3_object" {
  description = "An object to create inside de bucket"
  type        = string
  default     = ""
}