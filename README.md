# AWS ECS Fargate Terraform Module

This Terraform module creates an Amazon ECS cluster configured for Fargate and Fargate Spot capacity providers.

## Features

- Creates an ECS cluster with Fargate support
- Configurable Container Insights
- Support for both Fargate and Fargate Spot capacity providers
- CloudWatch log group with configurable retention
- Comprehensive tagging support

## Usage

```hcl
module "ecs_cluster" {
  source = "./modules/ecs-cluster"

  cluster_name             = "dd-demo"
  enable_container_insights = true
  capacity_providers       = ["FARGATE", "FARGATE_SPOT"]
  default_capacity_provider_strategy = [
    {
      capacity_provider = "FARGATE"
      weight           = 100
      base             = 1
    }
  ]
  log_retention_days = 30
  tags = {
    Environment = "development"
    Project     = "dd-demo"
  }
}
```

## Requirements

- Terraform >= 1.2.0
- AWS Provider ~> 5.0

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| cluster_name | Name of the ECS cluster | string | - | yes |
| enable_container_insights | Enable CloudWatch Container Insights | bool | true | no |
| capacity_providers | List of capacity providers | list(string) | ["FARGATE", "FARGATE_SPOT"] | no |
| log_retention_days | CloudWatch log retention in days | number | 30 | no |
| tags | Resource tags | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| cluster_id | ID of the ECS cluster |
| cluster_name | Name of the ECS cluster |
| cluster_arn | ARN of the ECS cluster |
| cloudwatch_log_group_name | Name of the CloudWatch log group |
