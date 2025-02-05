variable "environment" {
  description = "Environment name (e.g., dev, prod)"
  type        = string
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "log_retention_days" {
  description = "Number of days to retain logs in S3"
  type        = number
  default     = 30
}

variable "datadog_aws_account_id" {
  description = "Datadog AWS account ID for the region"
  type        = string
  # US region: 464622532012
  # EU region: 669770999999
  # Other regions may have different IDs
  default     = "464622532012"
}
