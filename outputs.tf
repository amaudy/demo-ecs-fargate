output "cluster_id" {
  description = "ID of the ECS cluster"
  value       = module.ecs_cluster.cluster_id
}

output "cluster_name" {
  description = "Name of the ECS cluster"
  value       = module.ecs_cluster.cluster_name
}

output "fastapi_alb_dns" {
  description = "DNS name of the FastAPI ALB"
  value       = module.fastapi_echo.alb_dns_name
}

output "fastapi_alb_name" {
  description = "Name of the FastAPI ALB"
  value       = module.fastapi_echo.alb_name
}

output "fastapi_service_name" {
  description = "Name of the FastAPI ECS service"
  value       = module.fastapi_echo.service_name
}

output "fastapi_task_definition" {
  description = "ARN of the FastAPI task definition"
  value       = module.fastapi_echo.task_definition_arn
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.vpc.private_subnet_ids
}
