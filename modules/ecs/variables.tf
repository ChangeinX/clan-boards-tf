variable "app_name" { type = string }
variable "vpc_id" { type = string }
variable "subnet_ids" { type = list(string) }
variable "alb_sg_id" { type = string }
variable "worker_target_group_arn" { type = string }
variable "messages_target_group_arn" { type = string }
variable "listener_arn" { type = string }
variable "region" { type = string }
variable "worker_image" { type = string }
variable "static_ip_image" { type = string }
variable "messages_image" { type = string }
variable "app_env" { type = string }
variable "db_endpoint" { type = string }
variable "db_password" { type = string }

variable "sync_base" { type = string }

variable "messages_table" { type = string }
variable "messages_table_arn" { type = string }
variable "appsync_events_url" { type = string }
variable "event_api_arn" { type = string }

variable "coc_api_token" { type = string }

variable "google_client_id" { type = string }
variable "google_client_secret" { type = string }
