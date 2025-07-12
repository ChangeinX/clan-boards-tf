# OpenTofu Web App Infrastructure

This configuration provisions an AWS environment for a containerized web application using Fargate on Graviton (ARM64) and an RDS Postgres database.

## Components
- VPC with public subnets and private subnets for the database
- Security groups for the ALB, ECS tasks and database
- Application Load Balancer with HTTPS termination and HTTP redirect
- ECS cluster with a task definition containing two containers
- Fargate service behind the ALB running on ARM64
- PostgreSQL RDS instance in private subnets with deletion protection
- Separate CloudWatch log groups for each container
- Secrets Manager stores worker environment variables

## Usage
1. Set the required variables in a `terraform.tfvars` file:

```hcl
app_image    = "<app image>"
worker_image = "<worker image>"
db_password  = "<strong password>"
certificate_arn = "<acm certificate arn>"
app_env = "production"
coc_api_token = "<clash of clans api token>"
```

The configuration stores these values in AWS Secrets Manager and generates a
random `SECRET_KEY` for the worker container.

2. Initialize and apply the configuration using [OpenTofu](https://opentofu.org/):

```bash
tofu init
tofu apply
```

The outputs will display the ALB DNS name and database endpoint.
