# OpenTofu Web App Infrastructure

This configuration provisions an AWS environment for a containerized web application using Fargate on Graviton (ARM64) and an RDS Postgres database. The code is organised into modules for easier reuse:

- `networking` creates the VPC, public subnets and private subnets for the database
- `alb` provisions the Application Load Balancer and related security group
- `rds` creates the Postgres database in the private subnets
- `ecs` sets up the ECS cluster, Fargate task definitions and services, CloudWatch log groups and Secrets Manager entries. The `static` service is registered in a Cloud Map namespace so the worker container can reach it internally at `static.<app_name>.internal`.
- `nat_instance` provisions a lightweight Amazon Linux 2023 EC2 instance that acts as a NAT. It automatically allocates an Elastic IP so all Fargate tasks egress from a single static address. The instance is reachable via SSH from `static_ip_allowed_ip` using the `static_ip_key_name` key pair for troubleshooting.

Each container logs to its own CloudWatch log group and the worker receives its environment via Secrets Manager including the `COC_API_TOKEN`.

## Usage
1. Set the required variables in a `terraform.tfvars` file:

```hcl
app_image           = "<app image>"
worker_image        = "<worker image>"
static_ip_image     = "<sync service image>"
static_ip_allowed_ip = "<your ip>/32"
static_ip_key_name  = "<ssh key name>"
db_allowed_ip = "<your ip>/32"
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

The outputs will display the ALB DNS name, database endpoint and the NAT instance's public IP and allocation ID.
