data "aws_secretsmanager_secret_version" "datadog_api_key" {
  secret_id = var.datadog_api_key_secret_arn
}

provider "datadog" {
  api_url = var.datadog_api_url
  api_key = data.aws_secretsmanager_secret_version.datadog_api_key.secret_string
  app_key = var.datadog_app_key
}
