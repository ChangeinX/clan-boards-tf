variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "app_name" {
  description = "Name prefix for resources"
  type        = string
  default     = "webapp"
}

variable "app_image" {
  description = "Docker image for the web application"
  type        = string
}

variable "worker_image" {
  description = "Docker image for the worker"
  type        = string
}

variable "app_env" {
  description = "Environment for the worker container"
  type        = string
  default     = "production"
}

variable "coc_api_token" {
  description = "API token for Clash of Clans"
  type        = string
  sensitive   = true
}

variable "google_client_id" {
  description = "Google OAuth client ID"
  type        = string
  sensitive   = true
}

variable "google_client_secret" {
  description = "Google OAuth client secret"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Password for the postgres database"
  type        = string
  sensitive   = true
}

variable "db_allowed_ip" {
  description = "CIDR allowed to remotely connect to the database"
  type        = string
}

variable "certificate_arn" {
  description = "ACM certificate ARN for HTTPS"
  type        = string
}

variable "api_host" {
  description = "Hostname for the API listener rule"
  type        = string
  default     = null
}



variable "static_ip_image" {
  description = "Docker image for the sync service running behind the static IP"
  type        = string
}

variable "static_ip_allowed_ip" {
  description = "CIDR allowed to SSH to the NAT instance"
  type        = string
}

variable "static_ip_key_name" {
  description = "EC2 key pair name used for the NAT instance"
  type        = string
}

variable "backend_bucket" {
  description = "S3 bucket for Terraform state"
  type        = string
}

variable "backend_dynamodb_table" {
  description = "DynamoDB table for state locking"
  type        = string
}

variable "frontend_bucket_name" {
  description = "S3 bucket to host the front-end"
  type        = string
}
