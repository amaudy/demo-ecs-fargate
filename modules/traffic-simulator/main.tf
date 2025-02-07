terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

locals {
  prefix = lookup(var.tags, "Project_code", "")
  name_prefix = local.prefix != "" ? "${local.prefix}-" : ""
  function_name = "${local.name_prefix}traffic-simulator-${var.environment}"
}

# Create zip file for Lambda
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/src"
  output_path = "${path.module}/traffic-simulator.zip"
}

# Create IAM role for the Lambda
resource "aws_iam_role" "traffic_simulator" {
  name = local.function_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# Attach basic Lambda execution policy
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.traffic_simulator.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Create Lambda function
resource "aws_lambda_function" "traffic_simulator" {
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  function_name    = local.function_name
  role            = aws_iam_role.traffic_simulator.arn
  handler         = "lambda_function.lambda_handler"
  runtime         = "python3.9"
  timeout         = 300
  memory_size     = 256

  environment {
    variables = {
      TARGET_URL        = var.target_url
      NUM_REQUESTS     = var.num_requests
      CONCURRENT_USERS = var.concurrent_users
    }
  }

  tags = var.tags
}

# Create CloudWatch Event Rule to trigger the Lambda
resource "aws_cloudwatch_event_rule" "traffic_simulator" {
  name                = local.function_name
  description         = "Trigger traffic simulation Lambda on a schedule"
  schedule_expression = var.schedule_expression
  is_enabled         = var.is_enabled

  tags = var.tags
}

# Attach the Lambda as a target for the CloudWatch Event Rule
resource "aws_cloudwatch_event_target" "traffic_simulator" {
  rule      = aws_cloudwatch_event_rule.traffic_simulator.name
  target_id = "TrafficSimulatorLambda"
  arn       = aws_lambda_function.traffic_simulator.arn
}

# Grant permission for CloudWatch Events to invoke the Lambda
resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowCloudWatchInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.traffic_simulator.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.traffic_simulator.arn
}
