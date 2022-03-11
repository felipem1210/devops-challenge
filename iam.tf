#-----------------------------------------------------------------------------------------------------------------------
# IAM ROLE FOR EC2 INSTANCES
#-----------------------------------------------------------------------------------------------------------------------

# To assign an IAM Role to an EC2 instance, we actually need to assign the "IAM Instance Profile"
resource "aws_iam_instance_profile" "ec2-instances" {
  name = "${local.prefix}-ec2-instance-profile"
  role = aws_iam_role.ec2-instances.name
}

# Create AWS role to attach to ec2 instances
resource "aws_iam_role" "ec2-instances" {
  name               = "${local.prefix}-ec2-instances"
  assume_role_policy = data.aws_iam_policy_document.ec2-instances.json

  lifecycle {
    create_before_destroy = true
  }
}

# Create the asume role policy to attach to role
data "aws_iam_policy_document" "ec2-instances" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# Create policy to access the bucket created
data "aws_iam_policy_document" "bucket" {
  statement {
    actions = [
      "s3:GetObject"
    ]
    resources = ["arn:aws:s3:::${aws_s3_bucket.bucket.id}/*"]
  }
  statement {
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::${aws_s3_bucket.bucket.id}"]
  }
}

# Create the policy with bucket permissions to attach to role
resource "aws_iam_policy" "ec2-instances" {
  name_prefix = "${local.prefix}-allow-bucket-read"
  description = "A policy that allow ec2 instances to read from S3 bucket."
  policy      = data.aws_iam_policy_document.bucket.json
}

# Attach policy created before in the role
resource "aws_iam_role_policy_attachment" "ec2-instances" {
  policy_arn = aws_iam_policy.ec2-instances.arn
  role       = aws_iam_role.ec2-instances.name

  lifecycle {
    create_before_destroy = true
  }
}