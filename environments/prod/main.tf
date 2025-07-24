terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

module "networking" {
  source   = "../../modules/networking"
  region   = var.region
  app_name = var.app_name
}

module "alb" {
  source            = "../../modules/alb"
  app_name          = var.app_name
  vpc_id            = module.networking.vpc_id
  public_subnet_ids = module.networking.public_subnet_ids
  certificate_arn   = var.certificate_arn
  api_host          = var.api_host
}

module "chat" {
  source   = "../../modules/chat"
  app_name = var.app_name
}

module "secrets" {
  source                   = "../../modules/secrets"
  app_name                 = var.app_name
  region                   = var.region
  app_env                  = var.app_env
  db_endpoint              = module.rds.db_endpoint
  db_password              = var.db_password
  messages_table           = module.chat.table_name
  chat_table               = module.chat.chat_table_name
  coc_api_token            = var.coc_api_token
  google_client_id         = var.google_client_id
  google_client_secret     = var.google_client_secret
  messages_allowed_origins = var.messages_allowed_origins
  user_allowed_origins     = var.user_allowed_origins
}

module "ecs" {
  source                       = "../../modules/ecs"
  app_name                     = var.app_name
  vpc_id                       = module.networking.vpc_id
  subnet_ids                   = module.networking.private_subnet_ids
  alb_sg_id                    = module.alb.alb_sg_id
  worker_target_group_arn      = module.alb.api_target_group_arn
  messages_target_group_arn    = module.alb.messages_target_group_arn
  user_target_group_arn        = module.alb.user_target_group_arn
  listener_arn                 = module.alb.https_listener_arn
  region                       = var.region
  worker_image                 = var.worker_image
  user_image                   = var.user_image
  messages_image               = var.messages_image
  messages_table_arn           = module.chat.table_arn
  chat_table_arn               = module.chat.chat_table_arn
  app_env_arn                  = module.secrets.app_env_arn
  database_url_arn             = module.secrets.database_url_arn
  secret_key_arn               = module.secrets.secret_key_arn
  aws_region_arn               = module.secrets.aws_region_arn
  messages_table_secret_arn    = module.secrets.messages_table_secret_arn
  chat_table_secret_arn        = module.secrets.chat_table_secret_arn
  coc_api_token_arn            = module.secrets.coc_api_token_arn
  google_client_id_arn         = module.secrets.google_client_id_arn
  google_client_secret_arn     = module.secrets.google_client_secret_arn
  messages_allowed_origins_arn = module.secrets.messages_allowed_origins_arn
  user_allowed_origins_arn     = module.secrets.user_allowed_origins_arn
  depends_on                   = [module.alb]
}

module "rds" {
  source             = "../../modules/rds"
  app_name           = var.app_name
  vpc_id             = module.networking.vpc_id
  private_subnet_ids = module.networking.public_subnet_ids
  vpc_cidr           = module.networking.vpc_cidr
  db_password        = var.db_password
  allowed_ip         = var.db_allowed_ip
}


module "nat_gateway" {
  source                 = "../../modules/nat_gateway"
  app_name               = var.app_name
  subnet_id              = module.networking.public_subnet_ids[0]
  private_route_table_id = module.networking.private_route_table_id
}

module "frontend" {
  source          = "../../modules/frontend"
  bucket_name     = var.frontend_bucket_name
  domain_names    = var.frontend_domain_names
  certificate_arn = var.frontend_certificate_arn
}
