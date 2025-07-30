variable "app_name" { type = string }

variable "interface_ipv4_cidrs" {
  type    = list(string)
  default = []
}

variable "interface_ipv6_cidrs" {
  type    = list(string)
  default = []
}
