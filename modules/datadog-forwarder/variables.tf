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

variable "datadog_api_key_secret_arn" {
  description = "ARN of the existing Secrets Manager secret containing the Datadog API key"
  type        = string
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
