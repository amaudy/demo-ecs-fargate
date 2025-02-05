variable "environment" {
  description = "Environment name"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "datadog_aws_account_id" {
  description = "Datadog AWS account ID for the region"
  type        = string
  # US region: 464622532012
  # EU region: 669770999999
  default     = "464622532012"
}

variable "datadog_external_id" {
  description = "Datadog integration external ID"
  type        = string
}

variable "alb_logs_bucket_arn" {
  description = "ARN of the S3 bucket for ALB logs"
  type        = string
}
