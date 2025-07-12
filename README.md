# OpenTofu Web App Infrastructure

This configuration provisions an AWS environment for a containerized web application using Fargate on Graviton (ARM64) and an RDS Postgres database. The code is organised into modules for easier reuse:

- `networking` creates the VPC, public subnets and private subnets for the database
- `alb` provisions the Application Load Balancer and related security group
- `rds` creates the Postgres database in the private subnets
- `ecs` sets up the ECS cluster, task definition and service, CloudWatch log groups and Secrets Manager entries
- `static_instance` runs a small EC2 instance with a fixed IP for the Clash of Clans API

Each container logs to its own CloudWatch log group and the worker receives its environment via Secrets Manager.

## Usage
1. Set the required variables in a `terraform.tfvars` file:

```hcl
app_image    = "<app image>"
worker_image = "<worker image>"
static_ip_image = "<image needing static IP>"
db_password  = "<strong password>"
certificate_arn = "<acm certificate arn>"
app_env = "production"
coc_api_token = "<clash of clans api token>"
```

2. Initialize and apply the configuration using [OpenTofu](https://opentofu.org/):

```bash
tofu init
tofu apply
```

The outputs will display the ALB DNS name, database endpoint and the static instance IP.
