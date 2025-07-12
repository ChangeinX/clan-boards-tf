variable "app_name" { type = string }
variable "vpc_cidr" { type = string }
variable "vpc_id" { type = string }
variable "private_subnet_ids" { type = list(string) }
variable "db_password" { type = string }
