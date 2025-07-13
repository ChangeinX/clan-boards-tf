terraform {
  backend "s3" {
    bucket         = var.backend_bucket
    key            = "state/terraform.tfstate"
    region         = var.region
    dynamodb_table = var.backend_dynamodb_table
    encrypt        = true
  }
}
