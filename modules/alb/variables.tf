variable "app_name" { type = string }
variable "vpc_id" { type = string }
variable "public_subnet_ids" { type = list(string) }
variable "certificate_arn" { type = string }
variable "api_host" {
  type    = string
  default = null
}
variable "messages_host" {
  type    = string
  default = null
}
