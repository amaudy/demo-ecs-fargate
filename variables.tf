variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
}

variable "vpc_tags" {
  description = "Tags to find the VPC"
  type        = map(string)
  default = {
    Environment = "development"
  }
}

variable "public_subnet_tags" {
  description = "Tags to find the public subnets"
  type        = map(string)
  default = {
    Environment = "development"
    Type        = "Public"
  }
}

variable "tags" {
  description = "Default tags for all resources"
  type        = map(string)
  default = {
    Terraform    = "true"
    Environment  = "development"
    Project      = "dd-demo"
    Project_code = "abc1234"
  }
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "dd-demo"
}

# Datadog Configuration
variable "datadog_api_key" {
  description = "Datadog API key for log forwarding"
  type        = string
  sensitive   = true
}

variable "datadog_api_key_secret_arn" {
  description = "ARN of the existing Secrets Manager secret containing the Datadog API key"
  type        = string
}

variable "datadog_api_url" {
  description = "The Datadog API URL"
  type        = string
  default     = "https://api.datadoghq.com/"
}

variable "datadog_app_key" {
  description = "Datadog APP key for API access"
  type        = string
  sensitive   = true
}
