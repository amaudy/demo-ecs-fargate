variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "target_url" {
  description = "Target URL for the traffic simulation (e.g., ALB DNS)"
  type        = string
}

variable "num_requests" {
  description = "Number of requests to send in each simulation run"
  type        = number
  default     = 10
}

variable "concurrent_users" {
  description = "Number of concurrent users/threads for simulation"
  type        = number
  default     = 5
}

variable "schedule_expression" {
  description = "CloudWatch Events schedule expression (e.g., rate(5 minutes))"
  type        = string
  default     = "rate(5 minutes)"
}

variable "is_enabled" {
  description = "Whether the CloudWatch Event rule is enabled"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
