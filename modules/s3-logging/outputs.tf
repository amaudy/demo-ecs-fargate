output "bucket_name" {
  description = "Name of the S3 bucket for ALB logs"
  value       = aws_s3_bucket.alb_logs.id
}

output "bucket_arn" {
  description = "ARN of the S3 bucket for ALB logs"
  value       = aws_s3_bucket.alb_logs.arn
}

output "alb_logs_bucket_arn" {
  description = "ARN of the ALB logs bucket"
  value       = aws_s3_bucket.alb_logs.arn
}

output "alb_logs_bucket_id" {
  description = "ID (name) of the ALB logs bucket"
  value       = aws_s3_bucket.alb_logs.id
}

output "aws_account_id" {
  description = "Current AWS account ID"
  value       = data.aws_caller_identity.current.account_id
}

output "aws_region" {
  description = "Current AWS region"
  value       = data.aws_region.current.name
}
