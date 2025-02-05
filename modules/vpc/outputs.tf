output "vpc_id" {
  description = "ID of the default VPC"
  value       = data.aws_vpc.default.id
}

output "vpc_cidr" {
  description = "CIDR block of the default VPC"
  value       = data.aws_vpc.default.cidr_block
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = data.aws_subnets.public.ids
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = data.aws_subnets.private.ids
}

output "default_security_group_id" {
  description = "ID of the default security group"
  value       = data.aws_security_group.default.id
}
