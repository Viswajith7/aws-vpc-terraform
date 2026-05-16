variable "project_name"         { type = string }
variable "environment"          { type = string }
variable "vpc_cidr"             { type = string }
variable "enable_dns_support"   { type = bool; default = true }
variable "enable_dns_hostnames" { type = bool; default = true }
variable "enable_flow_logs"     { type = bool; default = true }
variable "flow_logs_retention"  { type = number; default = 30 }
