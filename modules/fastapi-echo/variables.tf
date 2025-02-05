variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "task_family" {
  description = "Family name of the task definition"
  type        = string
}

variable "cluster_id" {
  description = "ID of the ECS cluster"
  type        = string
}

variable "cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
}

variable "task_cpu" {
  description = "CPU units for the task (1024 = 1 vCPU)"
  type        = number
  default     = 256
}

variable "task_memory" {
  description = "Memory for the task in MiB"
  type        = number
  default     = 512
}

variable "container_image" {
  description = "Docker image for the FastAPI Echo container"
  type        = string
  default     = "thatthep/fastapi-echo:latest"
}

variable "container_port" {
  description = "Port exposed by the container"
  type        = number
  default     = 8000
}

variable "container_environment" {
  description = "Environment variables for the container"
  type        = list(object({
    name  = string
    value = string
  }))
  default     = []
}

variable "log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 30
}

variable "vpc_tags" {
  description = "Tags to find the VPC"
  type        = map(string)
}

variable "public_subnet_tags" {
  description = "Tags to find the public subnets"
  type        = map(string)
}

variable "desired_count" {
  description = "Desired number of tasks"
  type        = number
  default     = 1
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "environment" {
  description = "Environment name (e.g., development, production)"
  type        = string
}

# Logging configuration
variable "enable_logging" {
  description = "Enable ALB access logging"
  type        = bool
  default     = false
}

variable "log_bucket_name" {
  description = "Name of the S3 bucket for ALB access logs"
  type        = string
  default     = ""
}

variable "log_bucket_prefix" {
  description = "Prefix for ALB access logs in the S3 bucket"
  type        = string
  default     = "alb-logs"
}
