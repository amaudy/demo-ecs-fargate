# Get VPC by tag
data "aws_vpc" "selected" {
  id = lookup(var.vpc_tags, "Name", null)
}

# Get current AWS account ID and region
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name
  prefix = lookup(var.tags, "Project_code", "")
  vpc_id = lookup(var.vpc_tags, "Name", "")
  subnet_ids = split(",", lookup(var.public_subnet_tags, "subnet-ids", ""))
  app_name = "${var.cluster_name}-fe"
  name_prefix = local.prefix != "" ? "${local.prefix}-" : ""
  resource_name = "${local.name_prefix}${local.app_name}"
  tags = merge(
    var.tags,
    {
      Name = local.resource_name
    }
  )
}

# Create security group for ALB
resource "aws_security_group" "alb" {
  name        = "${local.resource_name}-alb-sg"
  description = "Security group for FastAPI Echo ALB"
  vpc_id      = data.aws_vpc.selected.id

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.tags
}

# Create security group for ECS tasks
resource "aws_security_group" "ecs_tasks" {
  name        = "${local.resource_name}-ecs-tasks-sg"
  description = "Security group for FastAPI Echo ECS tasks"
  vpc_id      = data.aws_vpc.selected.id

  ingress {
    description     = "Allow inbound traffic from ALB"
    from_port       = var.container_port
    to_port         = var.container_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.tags
}

# Create ALB
resource "aws_lb" "main" {
  name               = "${local.resource_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets           = local.subnet_ids

  enable_deletion_protection = false

  # Enable access logging
  access_logs {
    bucket  = var.log_bucket_name
    prefix  = var.log_bucket_prefix
    enabled = var.enable_logging
  }

  tags = local.tags
}

# Create target group
resource "aws_lb_target_group" "main" {
  name        = "${local.resource_name}-tg"
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.selected.id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher            = "200"
    path               = "/health"
    port               = "traffic-port"
    protocol           = "HTTP"
    timeout            = 5
    unhealthy_threshold = 3
  }

  tags = local.tags
}

# Create listener
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}

# Task Definition
resource "aws_ecs_task_definition" "fastapi_echo" {
  family                   = local.resource_name
  requires_compatibilities = ["FARGATE"]
  network_mode            = "awsvpc"
  cpu                     = var.task_cpu
  memory                  = var.task_memory
  execution_role_arn      = aws_iam_role.ecs_execution_role.arn
  task_role_arn          = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name         = "fastapi-echo"
      image        = var.container_image
      essential    = true
      
      portMappings = [
        {
          containerPort = var.container_port
          hostPort     = var.container_port
          protocol     = "tcp"
        }
      ]

      environment = var.container_environment

      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:${var.container_port}/health || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/${local.resource_name}"
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }

      mountPoints = []
      volumesFrom = []
      
      linuxParameters = {
        initProcessEnabled = true
      }

      ulimits = [
        {
          name      = "nofile"
          softLimit = 65536
          hardLimit = 65536
        }
      ]
    }
  ])

  tags = var.tags
}

# ECS Service
resource "aws_ecs_service" "main" {
  name                               = "${local.resource_name}-service"
  cluster                           = var.cluster_id
  task_definition                   = aws_ecs_task_definition.fastapi_echo.arn
  desired_count                     = var.desired_count
  launch_type                       = "FARGATE"
  platform_version                  = "LATEST"
  health_check_grace_period_seconds = 60

  network_configuration {
    subnets          = local.subnet_ids
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.main.arn
    container_name   = "fastapi-echo"
    container_port   = var.container_port
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  deployment_controller {
    type = "ECS"
  }

  tags = var.tags
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "fastapi_echo" {
  name              = "/ecs/${local.resource_name}"
  retention_in_days = var.log_retention_days
  tags              = var.tags
}

# ECS Task Execution Role
resource "aws_iam_role" "ecs_execution_role" {
  name = "${local.resource_name}-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# ECS Task Execution Role Policy Attachment
resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ECS Task Role
resource "aws_iam_role" "ecs_task_role" {
  name = "${local.resource_name}-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}
