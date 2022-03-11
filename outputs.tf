output "alb_hostname" {
  description = "The DNS name of the ALB"
  value       = aws_lb.alb.dns_name
}

output "ec2_role_arn" {
  description = "The ARN of the role created for ec2 instances"
  value       = aws_iam_role.ec2-instances.arn
}