output "forwarder_arn" {
  description = "ARN of the Datadog Forwarder Lambda function"
  value       = aws_lambda_function.datadog_forwarder.arn
}

output "forwarder_role_arn" {
  description = "ARN of the IAM role used by the Datadog Forwarder"
  value       = aws_iam_role.datadog_forwarder.arn
}
