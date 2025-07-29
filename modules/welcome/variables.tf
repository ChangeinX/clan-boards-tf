variable "bucket_name" { type = string }

variable "domain_names" {
  type    = list(string)
  default = []
}

variable "certificate_arn" {
  type    = string
  default = null
}
