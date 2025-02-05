aws_region   = "us-east-1"
environment  = "development"
cluster_name = "dd-demo"

vpc_tags = {
  Environment = "development"
  Name        = "default"
}

public_subnet_tags = {
  Environment = "development"
  Type        = "Public"
}

tags = {
  Terraform    = "true"
  Environment  = "development"
  Project      = "dd-demo"
  Project_code = "abc1234"
}

# Datadog Configuration
# Get these values from Datadog AWS Integration page

