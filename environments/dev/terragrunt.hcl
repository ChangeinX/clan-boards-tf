include {
  path = find_in_parent_folders()
}

terraform {
  source = "../../modules/environment"
}

inputs = {
  env = "dev"
}

remote_state {
  backend = "s3"
  config = {
    bucket         = get_env("TF_BACKEND_BUCKET")
    key            = "state/dev/terraform.tfstate"
    region         = get_env("AWS_REGION", "us-east-1")
    dynamodb_table = get_env("TF_BACKEND_TABLE")
    encrypt        = true
  }
}
