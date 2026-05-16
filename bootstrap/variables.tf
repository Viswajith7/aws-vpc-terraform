variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name (used to prefix all resource names)"
  type        = string
  default     = "myapp-prod"
}
