#-----------------------------------------------------------------------------------------------------------------------
# S3 BUCKET ACCESED BY EC2 INSTANCES
#-----------------------------------------------------------------------------------------------------------------------

resource "aws_s3_bucket" "bucket" {
  bucket = var.s3_bucket_name
  acl    = "private"

  tags = merge(
    {
      "Name" = var.s3_bucket_name
    },
    var.custom_tags,
  )
}

resource "aws_s3_bucket_public_access_block" "bucket" {
  bucket                  = aws_s3_bucket.bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_object" "object" {
  key                    = var.s3_object
  bucket                 = aws_s3_bucket.bucket.id
  source                 = "${path.module}/templates/${var.s3_object}"
}
