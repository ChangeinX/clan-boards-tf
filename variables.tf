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

variable "db_password" {
  description = "Password for the postgres database"
  type        = string
  sensitive   = true
}

variable "certificate_arn" {
  description = "ACM certificate ARN for HTTPS"
  type        = string
}

variable "static_ip_image" {
  description = "Docker image for the static IP worker"
  type        = string
}
