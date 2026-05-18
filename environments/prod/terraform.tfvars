# environments/prod/terraform.tfvars
# ── Copy this file to root when deploying prod ──

aws_region   = "us-east-1"
project_name = "myapp"
environment  = "prod"
team_name    = "platform"

vpc_cidr           = "10.0.0.0/16"
availability_zones = ["us-east-1a", "us-east-1b"]

public_subnet_cidrs  = ["10.0.1.0/24", "10.0.4.0/24"]
private_subnet_cidrs = ["10.0.2.0/24", "10.0.5.0/24"]
db_subnet_cidrs      = ["10.0.3.0/24", "10.0.6.0/24"]

# Restrict to your corporate VPN CIDR in production!
allowed_ssh_cidrs = ["10.100.0.0/16"]

enable_flow_logs         = true
flow_logs_retention_days = 30
