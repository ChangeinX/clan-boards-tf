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

variable "cors_allowed_origins" {
  description = "Allowed CORS origins for all services"
  type        = list(string)
}

variable "session_max_age" {
  description = "Max age in seconds for JWT sessions"
  type        = string
}

variable "cookie_domain" {
  description = "Domain for the session cookie"
  type        = string
}

variable "cookie_secure" {
  description = "Whether the session cookie is secure"
  type        = bool
  default     = true
}

variable "db_password" {
  description = "Password for the postgres database"
  type        = string
  sensitive   = true
}

variable "db_username" {
  description = "Username for the postgres database"
  type        = string
  default     = "postgres"
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




variable "user_image" {
  description = "Docker image for the user service"
  type        = string
}

variable "messages_image" {
  description = "Docker image for the messages service"
  type        = string
}

variable "notifications_image" {
  description = "Docker image for the notifications service"
  type        = string
}

variable "recruiting_image" {
  description = "Docker image for the recruiting service"
  type        = string
}

variable "vapid_secret_name" {
  description = "Name of the VAPID keys secret"
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

variable "frontend_domain_names" {
  description = "Domain names for the front-end CloudFront distribution"
  type        = list(string)
  default     = []
}

variable "frontend_certificate_arn" {
  description = "ACM certificate ARN for the front-end distribution"
  type        = string
  default     = null
}


variable "welcome_bucket_name" {
  description = "S3 bucket to host the welcome page"
  type        = string
}

variable "welcome_domain_names" {
  description = "Domain names for the welcome page CloudFront distribution"
  type        = list(string)
  default     = []
}

variable "welcome_certificate_arn" {
  description = "ACM certificate ARN for the welcome page distribution"
  type        = string
  default     = null
}

variable "interface_ipv4_cidrs" {
  description = "IPv4 CIDRs allowed to access the interface"
  type        = list(string)
  default     = []
}

variable "interface_ipv6_cidrs" {
  description = "IPv6 CIDRs allowed to access the interface"
  type        = list(string)
  default     = []
}
