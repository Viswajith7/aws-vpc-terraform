# ─────────────────────────────────────────────────────────────
#  outputs.tf — values exposed to other Terraform stacks
# ─────────────────────────────────────────────────────────────

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = module.vpc.vpc_cidr
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.subnets.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private (app) subnets"
  value       = module.subnets.private_subnet_ids
}

output "db_subnet_ids" {
  description = "IDs of the DB subnets"
  value       = module.subnets.db_subnet_ids
}

output "db_subnet_group_name" {
  description = "RDS subnet group name"
  value       = module.subnets.db_subnet_group_name
}

output "sg_web_id" {
  description = "Security group for internet-facing ALB"
  value       = module.security_groups.sg_web_id
}

output "sg_app_id" {
  description = "Security group for application layer"
  value       = module.security_groups.sg_app_id
}

output "sg_db_id" {
  description = "Security group for database layer"
  value       = module.security_groups.sg_db_id
}

output "nat_gateway_ids" {
  description = "IDs of the NAT gateways"
  value       = module.nat_gateway.nat_gateway_ids
}
