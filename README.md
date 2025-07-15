# OpenTofu Web App Infrastructure

This configuration provisions an AWS environment for a containerized web application using Fargate on Graviton (ARM64) and an RDS Postgres database. The code is organised into modules for easier reuse:

- `networking` creates the VPC, public and private subnets for the database and sets up VPC
  endpoints for Secrets Manager, ECR, CloudWatch Logs and S3 so tasks can pull
  container images without internet access
- `alb` provisions the Application Load Balancer and related security group
- `rds` creates the Postgres database in the private subnets
- `ecs` sets up the ECS cluster, task definitions and services, CloudWatch log groups and Secrets Manager entries. The sync service is registered in Cloud Map so other tasks can reach it via `static.<app_name>.local`.
- `nat_instance` provisions a lightweight Amazon Linux 2023 EC2 instance that acts as a NAT. It automatically allocates an Elastic IP so all Fargate tasks egress from a single static address. The instance is reachable via SSH from `static_ip_allowed_ip` using the `static_ip_key_name` key pair for troubleshooting. The instance starts the iptables service on boot.
- `frontend` creates an S3 bucket configured for static website hosting so the web app can be served directly from S3.

The ECS service running the front-end container remains deployed for now to avoid downtime while migrating traffic.

Each container logs to its own CloudWatch log group and the worker receives its environment via Secrets Manager including the `COC_API_TOKEN` and Google OAuth credentials. The worker talks to the sync service at `static.<app_name>.local`.

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
api_host       = "api.example.com"
app_env = "production"
coc_api_token = "<clash of clans api token>"
google_client_id = "<google oauth client id>"
google_client_secret = "<google oauth client secret>"
backend_bucket = "<s3 bucket for state>"
backend_dynamodb_table = "<dynamodb table for locking>"
frontend_bucket_name = "<s3 bucket for frontend>"
```

2. Create the state bucket and DynamoDB table using the helper script. The
   region defaults to `us-east-1`:

```bash
./scripts/setup-backend.sh <backend_bucket> <backend_dynamodb_table> <region>
```
The script enables versioning, default encryption and blocks public access on
the bucket.

3. Initialize and apply the configuration using [OpenTofu](https://opentofu.org/):

```bash
tofu init
tofu apply
```

The outputs will display the ALB DNS name, database endpoint and the NAT instance's public IP and allocation ID.

## Environments
Separate Terraform roots are provided under `environments/dev`, `environments/qa` and `environments/prod`. Each folder uses its own state prefix so the stages are isolated.

Run Terraform from the desired environment directory, for example:

```bash
cd environments/dev
terraform init
terraform apply
```


## Continuous Integration
GitHub Actions validate the configuration on every pull request. Formatting and validation are run with OpenTofu.

Pushing to `main` automatically applies the configuration for the `dev` environment. Tags matching `qa-*` or `prod-*` trigger deployments to `qa` and `prod`.

