variable "app_name" { type = string }
variable "google_client_id" { type = string }

variable "domain_name" {
  type    = string
  default = null
}

variable "certificate_arn" {
  type    = string
  default = null
}
