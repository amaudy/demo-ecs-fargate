terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    datadog = {
      source  = "DataDog/datadog"
      version = "~> 3.30.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
}

# Configure the Datadog Provider
provider "datadog" {
  api_key  = var.datadog_api_key
  app_key  = var.datadog_app_key
  api_url  = "https://api.us5.datadoghq.com"
  validate = true
}

# Create ECS Cluster using the ecs-cluster module
module "vpc" {
  source = "./modules/vpc"
}

module "s3_logging" {
  source = "./modules/s3-logging"

  environment = var.environment
  tags        = var.tags
}

module "datadog_integration" {
  source = "./modules/datadog-integration"

  environment         = var.environment
  datadog_external_id = var.datadog_external_id
  alb_logs_bucket_arn = module.s3_logging.bucket_arn
  tags                = var.tags
}

module "ecs_cluster" {
  source = "./modules/ecs-cluster"

  cluster_name              = var.cluster_name
  enable_container_insights = true
  capacity_providers        = ["FARGATE", "FARGATE_SPOT"]
  default_capacity_provider_strategy = [
    {
      capacity_provider = "FARGATE"
      weight            = 100
      base              = 1
    }
  ]
  log_retention_days = 30
  tags               = var.tags
}

module "fastapi_echo" {
  source = "./modules/fastapi-echo"

  aws_region   = var.aws_region
  environment  = var.environment
  cluster_name = var.cluster_name
  cluster_id   = module.ecs_cluster.cluster_id
  task_family  = "${var.cluster_name}-fastapi-echo"

  # Task configuration
  task_cpu        = 256
  task_memory     = 512
  container_port  = 8000
  container_image = "thatthep/fastapi-echo:latest"
  desired_count   = 1

  # VPC configuration
  vpc_tags = {
    Name = module.vpc.vpc_id
  }
  public_subnet_tags = {
    subnet-ids = join(",", module.vpc.public_subnet_ids)
  }

  # Logging configuration
  enable_logging    = true
  log_bucket_name   = module.s3_logging.bucket_name
  log_bucket_prefix = "alb/${var.environment}"

  # Environment variables
  container_environment = [
    {
      name  = "ENVIRONMENT"
      value = var.environment
    }
  ]

  tags = var.tags

  depends_on = [
    module.vpc,
    module.s3_logging
  ]
}

module "datadog_dashboard" {
  source = "./modules/datadog-dashboard"

  environment     = var.environment
  alb_name        = module.fastapi_echo.alb_name
  datadog_api_key = var.datadog_api_key
  datadog_app_key = var.datadog_app_key

  depends_on = [
    module.datadog_integration,
    module.fastapi_echo
  ]
}

module "datadog_forwarder" {
  source = "./modules/datadog-forwarder"

  environment         = var.environment
  project_name        = var.project_name
  datadog_api_key     = var.datadog_api_key
  alb_logs_bucket_arn = module.s3_logging.alb_logs_bucket_arn
  alb_logs_bucket_id  = module.s3_logging.alb_logs_bucket_id
  tags                = var.tags
}
