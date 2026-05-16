variable "vpc_id"            { type = string }
variable "project_name"      { type = string }
variable "environment"       { type = string }
variable "vpc_cidr"          { type = string }
variable "allowed_ssh_cidrs" { type = list(string); default = [] }
