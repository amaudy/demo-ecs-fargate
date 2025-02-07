output "lambda_function_name" {
  description = "Name of the created Lambda function"
  value       = aws_lambda_function.traffic_simulator.function_name
}

output "lambda_function_arn" {
  description = "ARN of the created Lambda function"
  value       = aws_lambda_function.traffic_simulator.arn
}

output "cloudwatch_rule_name" {
  description = "Name of the CloudWatch Event rule"
  value       = aws_cloudwatch_event_rule.traffic_simulator.name
}

output "cloudwatch_rule_arn" {
  description = "ARN of the CloudWatch Event rule"
  value       = aws_cloudwatch_event_rule.traffic_simulator.arn
}
