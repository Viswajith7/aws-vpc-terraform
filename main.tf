# ─────────────────────────────────────────────────────────────
#  main.tf — root composition
#  Calls: vpc, subnets, nat-gateway, security-groups modules
# ─────────────────────────────────────────────────────────────

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = local.common_tags
  }
}

locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Owner       = var.team_name
  }
}

# ── VPC ────────────────────────────────────────
module "vpc" {
  source = "./modules/vpc"

  project_name         = var.project_name
  environment          = var.environment
  vpc_cidr             = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  enable_flow_logs     = var.enable_flow_logs
  flow_logs_retention  = var.flow_logs_retention_days
}

# ── Subnets ────────────────────────────────────
module "subnets" {
  source = "./modules/subnets"

  vpc_id               = module.vpc.vpc_id
  project_name         = var.project_name
  environment          = var.environment
  availability_zones   = var.availability_zones
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  db_subnet_cidrs      = var.db_subnet_cidrs
  internet_gateway_id  = module.vpc.internet_gateway_id
}

# ── NAT Gateways (one per AZ for HA) ──────────
module "nat_gateway" {
  source = "./modules/nat-gateway"

  project_name            = var.project_name
  environment             = var.environment
  public_subnet_ids       = module.subnets.public_subnet_ids
  private_subnet_ids      = module.subnets.private_subnet_ids
  availability_zones      = var.availability_zones
  private_route_table_ids = module.subnets.private_route_table_ids
}
# ── Security Groups ────────────────────────────
module "security_groups" {
  source = "./modules/security-groups"

  vpc_id            = module.vpc.vpc_id
  project_name      = var.project_name
  environment       = var.environment
  vpc_cidr          = var.vpc_cidr
  allowed_ssh_cidrs = var.allowed_ssh_cidrs
}
