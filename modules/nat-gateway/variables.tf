variable "project_name"          { type = string }
variable "environment"           { type = string }
variable "availability_zones"    { type = list(string) }
variable "public_subnet_ids"     { type = list(string) }
variable "private_subnet_ids"    { type = list(string) }
variable "private_route_table_ids" { type = list(string); default = [] }
