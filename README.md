# OpenTofu Web App Infrastructure


This configuration provisions an AWS environment for a containerized web application using Fargate on Graviton (ARM64) and an RDS Postgres database. The code is organised into modules for easier reuse:

- `networking` creates the VPC, public and private subnets for the database and sets up VPC
  endpoints for Secrets Manager, ECR, CloudWatch Logs and S3 so tasks can pull
  container images without internet access
- `alb` provisions the Application Load Balancer and related security group
- `rds` creates the Postgres database in the private subnets
- `secrets` stores application configuration in Secrets Manager for the ECS tasks.
- `ecs` sets up the ECS cluster, task definitions and services. The user service is registered in Cloud Map so other tasks can reach it via `user.<app_name>.local` and is exposed through the ALB at `/api/v1/friends`. It now requires the chat table ARN and related secret ARNs so tasks can read and write chat messages.
  The user task also receives database credentials from Secrets Manager.
- `notifications` connects the chat table stream to an SQS outbox with a Lambda function, exposes VAPID keys for push notifications and now outputs the outbox and DLQ queue URLs.
- `nat_gateway` provides outbound internet access for private subnets using an Elastic IP so Fargate tasks egress from a static address. It requires no maintenance or SSH access.
- `frontend` creates an S3 bucket configured for static website hosting and a CloudFront distribution that forwards the `If-None-Match` header so the web app can be served directly from S3.
- `chat` provisions a DynamoDB table used for the chat service with streams enabled. The table name, ARN and stream ARN are exported for other modules.

Each container logs to its own CloudWatch log group and the worker receives its environment via Secrets Manager along with Google OAuth credentials. The worker also loads `COC_EMAIL` and `COC_PASSWORD` from a shared secret. The worker talks to the user service at `user.<app_name>.local` or through the ALB path `/api/v1/friends`.
## Usage
1. Set the required variables in a `terraform.tfvars` file:

```hcl
worker_image        = "<worker image>"
user_image          = "<user service image>"
messages_image      = "<messages service image>"
db_allowed_ip = "<your ip>/32"
db_password  = "<strong password>"
db_username  = "postgres"
certificate_arn = "<acm certificate arn>"
api_host       = "api.example.com"
app_env = "production"
coc_api_token = "<clash of clans api token>"
google_client_id = "<google oauth client id>"
google_client_secret = "<google oauth client secret>"
messages_allowed_origins = ["https://app.example.com"]
user_allowed_origins     = ["https://app.example.com"]
notifications_allowed_origins = ["https://app.example.com"]
session_max_age      = "3600"
cookie_domain        = "example.com"
cookie_secure        = true
backend_bucket = "<s3 bucket for state>"
backend_dynamodb_table = "<dynamodb table for locking>"
frontend_bucket_name = "<s3 bucket for frontend>"
frontend_domain_names = ["app.example.com"]
frontend_certificate_arn = "<acm cert arn for frontend>"
```

2. Create the state bucket and DynamoDB table using the helper script. The
   region defaults to `us-east-1`:

```bash
./scripts/setup-backend.sh <backend_bucket> <backend_dynamodb_table> <region>
```
The script enables versioning, default encryption and blocks public access on
the bucket.

3. Initialize and apply the configuration from one of the environment directories using [OpenTofu](https://opentofu.org/):

```bash
cd environments/dev
tofu init
tofu apply
```

The outputs will display the ALB DNS name, database endpoint, the NAT gateway's
public IP and both chat table names.

Use `scripts/invalidate-cloudfront.sh` with the output `frontend_distribution_id` after uploading new files to the bucket to refresh cached content.

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

