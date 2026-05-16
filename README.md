# AWS Production VPC — Terraform + Jenkins Pipeline

A production-grade VPC built with reusable Terraform modules,
remote state in S3 + DynamoDB locking, and a fully automated
Jenkins pipeline with a manual approval gate for prod.

---

## Architecture overview

```
INTERNET
   │
   ▼
[Application Load Balancer]  ←── spans both AZs
   │
   ├── Public Subnet A (10.0.1.0/24)  │  Public Subnet B (10.0.4.0/24)
   │     NAT Gateway · Bastion        │    NAT Gateway · ALB node
   │
   ├── Private Subnet A (10.0.2.0/24) │  Private Subnet B (10.0.5.0/24)
   │     App servers · ECS tasks      │    App servers · ECS tasks
   │
   └── DB Subnet A (10.0.3.0/24)     │  DB Subnet B (10.0.6.0/24)
         RDS primary                  │    RDS standby
```

### Remote state

| Resource        | Purpose                          |
|-----------------|----------------------------------|
| S3 bucket       | Stores `terraform.tfstate`       |
| DynamoDB table  | Provides state locking (LockID)  |

---

## Directory layout

```
.
├── bootstrap/          ← run ONCE to create S3 + DynamoDB
│   ├── main.tf
│   └── variables.tf
├── backend.tf          ← S3 backend config (fill values from bootstrap)
├── main.tf             ← root composition, calls all modules
├── variables.tf
├── outputs.tf
├── Jenkinsfile         ← declarative pipeline
├── environments/
│   └── prod/
│       └── terraform.tfvars
└── modules/
    ├── vpc/            ← VPC, IGW, flow logs, S3 endpoint
    ├── subnets/        ← public / private / DB subnets, route tables, NACLs
    ├── nat-gateway/    ← EIP + NAT GW per AZ, private route
    └── security-groups/← web / app / db / bastion SGs
```

---

## Step-by-step setup

### 1. Bootstrap (run once per AWS account)

```bash
cd bootstrap/
terraform init          # local state is fine for bootstrap
terraform apply
# Note the bucket name and DynamoDB table name from outputs
```

### 2. Update backend.tf

Open `backend.tf` and replace the placeholder values:
```hcl
backend "s3" {
  bucket         = "<value from bootstrap output>"
  dynamodb_table = "<value from bootstrap output>"
  key            = "prod/vpc/terraform.tfstate"
  region         = "us-east-1"
  encrypt        = true
}
```

### 3. Local dev workflow

```bash
# Initialise with remote backend
terraform init

# Preview changes
terraform plan -var-file=environments/prod/terraform.tfvars

# Apply (normally done by Jenkins; run locally for dev only)
terraform apply -var-file=environments/prod/terraform.tfvars
```

### 4. Jenkins setup

1. Install plugins: Pipeline, AWS Steps, AnsiColor, Slack Notification
2. Add credentials (Manage Jenkins → Credentials):
   - `aws-access-key-id`     → AWS_ACCESS_KEY_ID
   - `aws-secret-access-key` → AWS_SECRET_ACCESS_KEY
   - `slack-webhook-url`     → incoming webhook URL
3. Create a Pipeline job pointing at this repo's `Jenkinsfile`
4. Set the IAM user/role permissions (see IAM policy below)

### 5. Jenkins pipeline stages

```
Checkout → Init → fmt check → Validate → Plan → [Approval*] → Apply → Notify
                                                    ↑
                                          prod only; 30-min timeout
```

---

## IAM policy for the Jenkins role

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:*",
        "logs:*",
        "iam:CreateRole", "iam:DeleteRole", "iam:PutRolePolicy",
        "iam:DeleteRolePolicy", "iam:GetRole", "iam:GetRolePolicy",
        "iam:PassRole", "iam:AttachRolePolicy", "iam:DetachRolePolicy",
        "iam:ListRolePolicies", "iam:ListAttachedRolePolicies"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": ["s3:GetObject","s3:PutObject","s3:DeleteObject","s3:ListBucket"],
      "Resource": [
        "arn:aws:s3:::myapp-prod-tfstate-*",
        "arn:aws:s3:::myapp-prod-tfstate-*/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": ["dynamodb:GetItem","dynamodb:PutItem","dynamodb:DeleteItem"],
      "Resource": "arn:aws:dynamodb:*:*:table/myapp-prod-tflock"
    }
  ]
}
```

---

## Key concepts explained

### Why S3 + DynamoDB for state?

Terraform's state file records every resource it manages.
If two engineers (or two Jenkins runs) apply at the same time,
they will corrupt the state. The solution:
- **S3** stores the single source of truth (with versioning so you can roll back)
- **DynamoDB** provides a distributed lock — Terraform writes a `LockID` row before
  starting and deletes it when done. A second apply waits or fails fast.

### Why one NAT Gateway per AZ?

A single NAT GW is a single point of failure. If `us-east-1a` loses
connectivity, private instances in `us-east-1b` would also lose egress.
One NAT GW per AZ costs more but survives AZ failures.

### Why layered security groups (web → app → db)?

No security group rule allows the internet directly into the app or DB tier.
Traffic must pass web SG → app SG → db SG. A compromised web server
cannot directly reach the database port.

### Why NACLs too?

Security groups are stateful (return traffic auto-allowed).
NACLs are stateless and evaluated before SGs, so they provide a second
independent deny layer. The private NACL explicitly blocks all direct
internet ingress even if a SG rule is accidentally opened.

---

## Tear-down

```bash
# Tick the DESTROY checkbox in Jenkins, or run locally:
terraform destroy -var-file=environments/prod/terraform.tfvars
```

The bootstrap S3 bucket and DynamoDB table have `prevent_destroy = true`.
To delete them, remove that lifecycle block first.
