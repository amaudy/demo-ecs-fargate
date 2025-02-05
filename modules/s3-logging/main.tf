# Get current AWS account ID
data "aws_caller_identity" "current" {}

# Get current AWS region
data "aws_region" "current" {}

# Get ALB account ID for the region
locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name
  
  # AWS ALB account IDs by region
  alb_account_ids = {
    us-east-1      = "127311923021"
    us-east-2      = "033677994240"
    us-west-1      = "027434742980"
    us-west-2      = "797873946194"
    af-south-1     = "098369216593"
    ap-east-1      = "754344448648"
    ap-southeast-1 = "114774131450"
    ap-southeast-2 = "783225319266"
    ap-southeast-3 = "589379963580"
    ap-south-1     = "718504428378"
    ap-northeast-1 = "582318560864"
    ap-northeast-2 = "600734575887"
    ap-northeast-3 = "383597477331"
    ca-central-1   = "985666609251"
    eu-central-1   = "054676820928"
    eu-west-1      = "156460612806"
    eu-west-2      = "652711504416"
    eu-west-3      = "009996457667"
    eu-south-1     = "635631232127"
    eu-north-1     = "897822967062"
    me-south-1     = "076674570225"
    sa-east-1      = "507241528517"
  }
  
  alb_account_id = local.alb_account_ids[local.region]
  
  prefix = lookup(var.tags, "Project_code", "")
  # Don't include Project_code prefix in bucket name to avoid recreation
  bucket_name = "alb-logs-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}-${var.environment}"
  tags = merge(
    var.tags,
    {
      Name = "${local.prefix}-alb-logs-${var.environment}"
    }
  )
}

# Create S3 bucket for ALB logs
resource "aws_s3_bucket" "alb_logs" {
  bucket = local.bucket_name
  tags   = local.tags
}

# Enable versioning
resource "aws_s3_bucket_versioning" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Lifecycle rules
resource "aws_s3_bucket_lifecycle_configuration" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  rule {
    id     = "cleanup_old_logs"
    status = "Enabled"

    expiration {
      days = var.log_retention_days
    }
  }
}

# ALB log delivery policy
resource "aws_s3_bucket_policy" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowALBLogDelivery"
        Effect    = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${local.alb_account_id}:root"
        }
        Action = "s3:PutObject"
        Resource = [
          "${aws_s3_bucket.alb_logs.arn}/*",
          aws_s3_bucket.alb_logs.arn
        ]
      },
      {
        Sid       = "AllowDatadogLogCollection"
        Effect    = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.datadog_aws_account_id}:root"
        }
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          "${aws_s3_bucket.alb_logs.arn}/*",
          aws_s3_bucket.alb_logs.arn
        ]
      }
    ]
  })
}
