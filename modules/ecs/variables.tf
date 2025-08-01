variable "app_name" { type = string }
variable "vpc_id" { type = string }
variable "subnet_ids" { type = list(string) }
variable "alb_sg_id" { type = string }
variable "worker_target_group_arn" { type = string }
variable "messages_target_group_arn" { type = string }
variable "user_target_group_arn" { type = string }
variable "notifications_target_group_arn" { type = string }
variable "listener_arn" { type = string }
variable "region" { type = string }
variable "worker_image" { type = string }
variable "user_image" { type = string }
variable "messages_image" { type = string }
variable "notifications_image" { type = string }

variable "chat_table_arn" { type = string }

variable "app_env_arn" { type = string }
variable "database_url_arn" { type = string }
variable "database_username_arn" { type = string }
variable "database_password_arn" { type = string }
variable "secret_key_arn" { type = string }
variable "aws_region_arn" { type = string }
variable "chat_table_secret_arn" { type = string }
variable "coc_api_token_arn" { type = string }
variable "google_client_id_arn" { type = string }
variable "google_client_secret_arn" { type = string }
variable "messages_allowed_origins_arn" { type = string }
variable "user_allowed_origins_arn" { type = string }
variable "messages_allowed_origins_name" { type = string }
variable "user_allowed_origins_name" { type = string }
variable "notifications_allowed_origins_arn" { type = string }
variable "notifications_allowed_origins_name" { type = string }
variable "notifications_queue_url" { type = string }
variable "notifications_queue_arn" { type = string }
variable "notifications_dlq_url" { type = string }
variable "vapid_secret_arn" { type = string }

variable "jwt_signing_key_arn" { type = string }
variable "session_max_age_arn" { type = string }
variable "cookie_domain_arn" { type = string }
variable "cookie_secure_arn" { type = string }
variable "redis_url_arn" { type = string }

variable "openai_moderation_arn" { type = string }
variable "perspective_api_key_arn" { type = string }
