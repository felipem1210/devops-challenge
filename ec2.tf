#----------------------------------------------------------------------------------------------------------------------
# CREATE EC2 AUTOSCALING GROUP WITH LAUNCH TEMPLATE.
# ----------------------------------------------------------------------------------------------------------------------

# ---------------------------------------------------------------------------------------------------------------------
# GET UBUNTU AMI ID
# ---------------------------------------------------------------------------------------------------------------------
data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"]
}

# ---------------------------------------------------------------------------------------------------------------------
# SETUP USER DATA
# ---------------------------------------------------------------------------------------------------------------------
data "template_file" "user_data" {
  template = file("${path.module}/templates/user-data.tpl")
  vars = {
    bucket_name = var.s3_bucket_name
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# PLACEMENT GROUP AND AUTOSCALING GROUP
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_placement_group" "this" {
  name     = local.prefix
  strategy = "spread"
}

resource "aws_autoscaling_group" "this" {
  name                      = "${local.prefix}-asg"
  max_size                  = var.max_asg_size
  min_size                  = var.min_asg_size
  health_check_grace_period = var.asg_health_check_grace_period
  health_check_type         = var.asg_health_check_type
  desired_capacity          = var.asg_desired_capacity
  force_delete              = var.asg_force_delete
  vpc_zone_identifier       = aws_subnet.private.*.id
  target_group_arns         = [aws_lb_target_group.tg.arn]
  
  launch_template {
    id      = aws_launch_template.this.id
    version = aws_launch_template.this.latest_version
  }

  tag {
    key                 = "Name"
    value               = "${local.prefix}-asg"
    propagate_at_launch = true
  }

  timeouts {
    delete = "15m"
  }
}

resource "aws_autoscaling_policy" "scale_up" {
    name                   = "${local.prefix}-sg-scale-u"
    scaling_adjustment     = 1
    adjustment_type        = "ChangeInCapacity"
    cooldown               = 300
    autoscaling_group_name = aws_autoscaling_group.this.name
}

resource "aws_autoscaling_policy" "scale_down" {
    name                   = "${local.prefix}-sg-scale-down"
    scaling_adjustment     = -1
    adjustment_type        = "ChangeInCapacity"
    cooldown               = 300
    autoscaling_group_name = aws_autoscaling_group.this.name
}

resource "aws_cloudwatch_metric_alarm" "cpu-high" {
    alarm_name = "${local.prefix}-cpu-asg-high"
    comparison_operator = "GreaterThanOrEqualToThreshold"
    evaluation_periods = "2"
    metric_name = "CPUUtilization"
    namespace = "AWS/EC2"
    period = "300"
    statistic = "Average"
    threshold = var.cpu_maximum_value_scale_up
    alarm_description = "This metric monitors ec2 cpu for high utilization on them"
    alarm_actions = [aws_autoscaling_policy.scale_up.arn]
    dimensions = {
        AutoScalingGroupName = aws_autoscaling_group.this.name
    }
}

resource "aws_cloudwatch_metric_alarm" "memory-low" {
    alarm_name = "${local.prefix}-cpu-asg-low"
    comparison_operator = "LessThanOrEqualToThreshold"
    evaluation_periods = "2"
    metric_name = "CPUUtilization"
    namespace = "AWS/EC2"
    period = "300"
    statistic = "Average"
    threshold = var.cpu_minimum_value_scale_down
    alarm_description = "This metric monitors ec2 cpu for low utilization on them"
    alarm_actions = [aws_autoscaling_policy.scale_down.arn]
    dimensions = {
        AutoScalingGroupName = aws_autoscaling_group.this.name
    }
}

# ---------------------------------------------------------------------------------------------------------------------
# LAUNCH TEMPLATE
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_launch_template" "this" {
  name                   = "${local.prefix}-launch-template"
  image_id               = var.ami_id == "" ? data.aws_ami.ubuntu.id : var.ami_id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.instance.id]
  user_data              = base64encode(data.template_file.user_data.rendered)
  key_name               = var.key_pair_name != "" ? var.key_pair_name : null

  iam_instance_profile {
    arn  = aws_iam_instance_profile.ec2-instances.arn
  }

  tag_specifications {
    resource_type = "instance"

    tags = merge(
      {
        "Name" = "${local.prefix}-private"
      },
      var.custom_tags,
    )
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE SECURITY GROUP TO CONTROL TRAFFIC IN AND OUT OF THE SERVER
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_security_group" "instance" {
  name                   = "${local.prefix}-sg"
  description            = "Security Group for EC2 instances"
  vpc_id                 = aws_vpc.this.id
  revoke_rules_on_delete = "true"

  lifecycle {
    create_before_destroy = true
  }
  tags = merge(
    {
      "Name" = "${local.prefix}-ec2-sg"
    },
    var.custom_tags,
  )

  egress {
    description = "Allow all outbound IPv4 traffic."
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  dynamic "ingress" {
    for_each = var.ec2_ingress_rules
    content {
      description     = "Allow inbound access to port ${ingress.value["port"]}."
      from_port       = ingress.value["port"]
      to_port         = ingress.value["port"]
      protocol        = "tcp"
      cidr_blocks     = ingress.value["cidr_block"] != [] ? ingress.value["cidr_block"] : null
      security_groups = ingress.value["port"] == 80 ? [aws_security_group.lb_sg.id] : null
    }
  }
}