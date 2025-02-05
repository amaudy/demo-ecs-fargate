variable "environment" {
  description = "Environment name"
  type        = string
}

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "datadog_api_key" {
  description = "Datadog API key"
  type        = string
  sensitive   = true
}

variable "alb_logs_bucket_arn" {
  description = "ARN of the S3 bucket containing ALB logs"
  type        = string
}

variable "alb_logs_bucket_id" {
  description = "ID (name) of the S3 bucket containing ALB logs"
  type        = string
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}
