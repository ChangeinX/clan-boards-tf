variable "app_name" {
  description = "Application name for resource naming"
  type        = string
}

variable "app_env" {
  description = "Application environment (dev, qa, prod)"
  type        = string
}

variable "lambda_artifacts_bucket" {
  description = "S3 bucket containing Lambda deployment artifacts"
  type        = string
}

variable "lambda_s3_key" {
  description = "S3 key for the refresh worker lambda zip file"
  type        = string
  default     = "coc-refresh-worker-lambda.zip"
}

variable "database_url_arn" {
  description = "ARN of the database URL secret in Secrets Manager"
  type        = string
}

variable "redis_url_arn" {
  description = "ARN of the Redis URL secret in Secrets Manager"
  type        = string
}

variable "coc_email_arn" {
  description = "ARN of the CoC email secret in Secrets Manager"
  type        = string
}

variable "coc_password_arn" {
  description = "ARN of the CoC password secret in Secrets Manager"
  type        = string
}

variable "vpc_config_enabled" {
  description = "Enable VPC configuration for Lambda (required for RDS/Redis access)"
  type        = bool
  default     = true
}

variable "vpc_id" {
  description = "VPC ID for Lambda security group"
  type        = string
  default     = ""
}

variable "lambda_subnet_ids" {
  description = "List of subnet IDs for Lambda VPC configuration"
  type        = list(string)
  default     = []
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 14
}

variable "schedule_expression" {
  description = "CloudWatch Events schedule expression"
  type        = string
  default     = "rate(2 minutes)"
}