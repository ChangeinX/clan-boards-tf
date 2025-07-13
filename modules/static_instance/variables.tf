variable "app_name" { type = string }
variable "vpc_id" { type = string }
variable "subnet_id" { type = string }
variable "rds_sg_id" { type = string }
variable "image" { type = string }
variable "db_endpoint" { type = string }
variable "db_password" { type = string }
variable "coc_api_token" { type = string }
variable "allowed_ip" { type = string }
variable "key_name" { type = string }

variable "ecs_sg_id" {
  description = "Security group id of the ECS tasks that need to access the static instance"
  type        = string
}

variable "worker_port" {
  description = "Port on which the static instance exposes its API"
  type        = number
  default     = 8000
}

variable "region" { type = string }
