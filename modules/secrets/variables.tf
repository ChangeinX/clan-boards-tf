variable "app_name" { type = string }
variable "region" { type = string }
variable "app_env" { type = string }
variable "db_endpoint" { type = string }
variable "db_username" { type = string }
variable "db_password" { type = string }
variable "chat_table" { type = string }
variable "coc_api_token" { type = string }
variable "google_client_id" { type = string }
variable "google_client_secret" { type = string }
variable "cors_allowed_origins" { type = list(string) }

variable "session_max_age" {
  type = string
}

variable "cookie_domain" {
  type = string
}

variable "cookie_secure" {
  type    = bool
  default = true
}
