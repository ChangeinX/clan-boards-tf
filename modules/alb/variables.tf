variable "app_name" { type = string }
variable "vpc_id" { type = string }
variable "public_subnet_ids" { type = list(string) }
variable "certificate_arn" { type = string }
variable "api_host" {
  type    = string
  default = null
}
variable "waf_web_acl_arn" {
  type    = string
  default = null
}
