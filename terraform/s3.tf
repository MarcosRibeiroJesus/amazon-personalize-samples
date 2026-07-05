data "aws_caller_identity" "current" {}

# S3 Bucket for Personalize data
resource "aws_s3_bucket" "personalize_data" {
  bucket = "${var.s3_bucket_prefix}-personalize-data-${data.aws_caller_identity.current.account_id}-${var.aws_region}"
}

# Block public access
resource "aws_s3_bucket_public_access_block" "personalize_data" {
  bucket = aws_s3_bucket.personalize_data.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable versioning
resource "aws_s3_bucket_versioning" "personalize_data" {
  bucket = aws_s3_bucket.personalize_data.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "personalize_data" {
  bucket = aws_s3_bucket.personalize_data.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 bucket policy for Personalize
resource "aws_s3_bucket_policy" "personalize_data" {
  bucket = aws_s3_bucket.personalize_data.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "PersonalizeAccess"
        Effect = "Allow"
        Principal = {
          Service = "personalize.amazonaws.com"
        }
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.personalize_data.arn,
          "${aws_s3_bucket.personalize_data.arn}/*"
        ]
      }
    ]
  })
}
