variable "app_name" { type = string }
variable "region" { type = string }

variable "google_oauth_web_client_id" {
  description = "Google OAuth 2.0 Web Client Id used by the PWA"
  type        = string
}

variable "vpc_cidr" { type = string }

variable "ecs_task_role_arn" {
  description = "ARN of the ECS task role allowed to publish"
  type        = string
}
