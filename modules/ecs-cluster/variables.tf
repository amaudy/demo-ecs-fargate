variable "cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
}

variable "enable_container_insights" {
  description = "Enable CloudWatch Container Insights for the cluster"
  type        = bool
  default     = true
}

variable "capacity_providers" {
  description = "List of capacity providers to use for the cluster"
  type        = list(string)
  default     = ["FARGATE", "FARGATE_SPOT"]
}

variable "default_capacity_provider_strategy" {
  description = "Default capacity provider strategy"
  type = list(object({
    capacity_provider = string
    weight           = number
    base             = number
  }))
  default = [
    {
      capacity_provider = "FARGATE"
      weight           = 100
      base             = 1
    }
  ]
}

variable "log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 30
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}
