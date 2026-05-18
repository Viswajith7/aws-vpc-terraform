# ─────────────────────────────────────────────────────────────
#  variables.tf — all configurable inputs
# ─────────────────────────────────────────────────────────────

variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Short slug used to prefix all resource names"
  type        = string
}

variable "environment" {
  description = "Deployment environment (prod / staging / dev)"
  type        = string
  validation {
    condition     = contains(["prod", "staging", "dev"], var.environment)
    error_message = "environment must be prod, staging, or dev."
  }
}

variable "team_name" {
  description = "Owning team for tag purposes"
  type        = string
  default     = "platform"
}

# ── Networking ─────────────────────────────────
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of AZs to deploy into (min 2)"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets (one per AZ)"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.4.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private (app) subnets (one per AZ)"
  type        = list(string)
  default     = ["10.0.2.0/24", "10.0.5.0/24"]
}

variable "db_subnet_cidrs" {
  description = "CIDR blocks for database subnets (one per AZ)"
  type        = list(string)
  default     = ["10.0.3.0/24", "10.0.6.0/24"]
}

# ── Security ───────────────────────────────────
variable "allowed_ssh_cidrs" {
  description = "CIDRs allowed to reach the bastion host on port 22"
  type        = list(string)
  default     = [] # lock down to VPN CIDR in prod
}

# ── Observability ──────────────────────────────
variable "enable_flow_logs" {
  description = "Enable VPC Flow Logs to CloudWatch"
  type        = bool
  default     = true
}

variable "flow_logs_retention_days" {
  description = "CloudWatch log retention in days for flow logs"
  type        = number
  default     = 30
}
