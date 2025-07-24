variable "app_name" { type = string }
variable "vpc_id" { type = string }
variable "subnet_ids" { type = list(string) }
variable "alb_sg_id" { type = string }
variable "worker_target_group_arn" { type = string }
variable "messages_target_group_arn" { type = string }
variable "user_target_group_arn" { type = string }
variable "listener_arn" { type = string }
variable "region" { type = string }
variable "worker_image" { type = string }
variable "user_image" { type = string }
variable "messages_image" { type = string }

variable "messages_table_arn" { type = string }
variable "chat_table_arn" { type = string }

variable "app_env_arn" { type = string }
variable "database_url_arn" { type = string }
variable "secret_key_arn" { type = string }
variable "aws_region_arn" { type = string }
variable "messages_table_secret_arn" { type = string }
variable "chat_table_secret_arn" { type = string }
variable "coc_api_token_arn" { type = string }
variable "google_client_id_arn" { type = string }
variable "google_client_secret_arn" { type = string }

variable "messages_allowed_origins_arn" { type = string }
variable "user_allowed_origins_arn" { type = string }
