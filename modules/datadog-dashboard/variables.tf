variable "alb_name" {
  description = "Name of the ALB to monitor"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "datadog_api_key" {
  description = "Datadog API key"
  type        = string
  sensitive   = true
}

variable "datadog_app_key" {
  description = "Datadog Application key"
  type        = string
  sensitive   = true
}
