output "role_arn" {
  description = "ARN of the Datadog AWS integration role"
  value       = aws_iam_role.datadog_integration.arn
}

output "role_name" {
  description = "Name of the Datadog AWS integration role"
  value       = aws_iam_role.datadog_integration.name
}
