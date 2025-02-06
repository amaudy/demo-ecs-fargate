variable "environment" {
  description = "Environment name (e.g., development, production)"
  type        = string
}

variable "service_name" {
  description = "Name of the service to monitor (e.g., ecom-api)"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = list(string)
  default     = []
}
