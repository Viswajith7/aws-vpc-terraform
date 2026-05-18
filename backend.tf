# ─────────────────────────────────────────────────────────────
#  backend.tf  — remote state in S3 with DynamoDB locking
#  Fill in bucket/dynamodb_table from bootstrap outputs
# ─────────────────────────────────────────────────────────────

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    # ── Values produced by bootstrap/main.tf ──
    bucket         = "myapp-prod-tfstate-520235901820" # <── replace
    key            = "prod/vpc/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "myapp-prod-tflock" # <── replace

    # Optional: restrict access via IAM role assumed by Jenkins
    # role_arn = "arn:aws:iam::123456789012:role/TerraformRole"
  }
}
