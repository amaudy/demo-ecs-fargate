data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

# Create zip file for Lambda deployment
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda_function.py"
  output_path = "${path.module}/datadog-forwarder.zip"
}

locals {
  prefix = lookup(var.tags, "Project_code", "")
  name_prefix = local.prefix != "" ? "${local.prefix}-" : ""
  function_name = "${local.name_prefix}datadog-forwarder-${var.environment}"
}

# Create IAM role for the Datadog Forwarder Lambda
resource "aws_iam_role" "datadog_forwarder" {
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

  tags = var.tags
}

# Create IAM policy for the Datadog Forwarder
resource "aws_iam_role_policy" "datadog_forwarder" {
  name = "${local.function_name}-policy"
  role = aws_iam_role.datadog_forwarder.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${local.function_name}:*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          var.alb_logs_bucket_arn,
          "${var.alb_logs_bucket_arn}/*"
        ]
      }
    ]
  })
}

# Store Datadog API key in AWS Secrets Manager
resource "aws_secretsmanager_secret" "datadog_api_key" {
  name        = "datadog-api-key-${var.environment}"
  description = "Datadog API Key for Lambda Forwarder"
  tags        = var.tags
}

resource "aws_secretsmanager_secret_version" "datadog_api_key" {
  secret_id     = aws_secretsmanager_secret.datadog_api_key.id
  secret_string = var.datadog_api_key
}

# Create Lambda function for Datadog Forwarder
resource "aws_lambda_function" "datadog_forwarder" {
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  function_name    = local.function_name
  role            = aws_iam_role.datadog_forwarder.arn
  handler         = "lambda_function.lambda_handler"
  runtime         = "python3.9"
  timeout         = 300
  memory_size     = 1024
  tags            = var.tags

  environment {
    variables = {
      DD_API_KEY_SECRET_ARN = aws_secretsmanager_secret.datadog_api_key.arn
      DD_SITE               = "us5.datadoghq.com"
      DD_TAGS               = join(",", [
        "env:${var.environment}",
        "project:${var.project_name}",
        "project_code:${var.tags["Project_code"]}",
        "terraform:${var.tags["Terraform"]}"
      ])
    }
  }
}

# Create CloudWatch Log Group for Lambda
resource "aws_cloudwatch_log_group" "datadog_forwarder" {
  name              = "/aws/lambda/${local.function_name}"
  retention_in_days = 14
  tags             = var.tags

  lifecycle {
    prevent_destroy = false
    ignore_changes  = [tags]
  }
}

# S3 bucket notification for ALB logs
resource "aws_s3_bucket_notification" "alb_logs" {
  bucket = var.alb_logs_bucket_id

  lambda_function {
    lambda_function_arn = aws_lambda_function.datadog_forwarder.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "alb/${var.environment}/AWSLogs/${data.aws_caller_identity.current.account_id}/elasticloadbalancing/${data.aws_region.current.name}/"
  }
}

# Lambda permission for S3 invocation
resource "aws_lambda_permission" "s3" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.datadog_forwarder.arn
  principal     = "s3.amazonaws.com"
  source_arn    = var.alb_logs_bucket_arn
}

# Add additional permissions for Lambda basic execution
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.datadog_forwarder.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Add permissions to read from Secrets Manager
resource "aws_iam_role_policy" "secrets_access" {
  name = "${local.function_name}-secrets"
  role = aws_iam_role.datadog_forwarder.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [aws_secretsmanager_secret.datadog_api_key.arn]
      }
    ]
  })
}
