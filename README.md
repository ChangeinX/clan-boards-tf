# OpenTofu Web App Infrastructure

This configuration provisions an AWS environment for a containerized web application using Fargate and an RDS Postgres database.

## Components
- VPC with public subnets
- Security groups for the ALB, ECS tasks and database
- Application Load Balancer
- ECS cluster with a task definition containing two containers
- Fargate service behind the ALB
- PostgreSQL RDS instance

## Usage
1. Set the required variables in a `terraform.tfvars` file:

```hcl
app_image    = "<app image>"
worker_image = "<worker image>"
db_password  = "<strong password>"
```

2. Initialize and apply the configuration using [OpenTofu](https://opentofu.org/):

```bash
tofu init
tofu apply
```

The outputs will display the ALB DNS name and database endpoint.
