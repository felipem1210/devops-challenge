# ---------------------------------------------------------------------------------------------------------------------
# CREATE ALB AND TARGET GROUP
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_lb" "alb" {
  name               = "${local.prefix}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = aws_subnet.public.*.id

  enable_deletion_protection = false

#   access_logs {
#     bucket  = aws_s3_bucket.lb_logs.bucket
#     prefix  = "test-lb"
#     enabled = true
#   }

  tags = merge(
    {
      Name = format("%s-%s",local.prefix, "alb")
    },
    var.custom_tags
  )
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

resource "aws_lb_target_group" "tg" {
  name     = "${local.prefix}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.this.id
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE SECURITY GROUP TO CONTROL TRAFFIC OF ALB
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_security_group" "lb_sg" {
  name                   = "${local.prefix}-lg_sg"
  description            = "Security Group for ALB"
  vpc_id                 = aws_vpc.this.id
  revoke_rules_on_delete = "true"

  lifecycle {
    create_before_destroy = true
  }
  tags = merge(
    {
      "Name" = "${local.prefix}-alb-sg"
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

   ingress {
    description = "Allow all inbound IPv4 traffic to port 80."
    from_port   = 80
    to_port     = 80
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }
}