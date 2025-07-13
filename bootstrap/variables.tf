variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "state_bucket" {
  description = "Name of S3 bucket for Terraform state"
  type        = string
}

variable "state_table" {
  description = "Name of DynamoDB table for state locking"
  type        = string
}
