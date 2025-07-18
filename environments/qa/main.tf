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

module "ecs" {
  source                    = "../../modules/ecs"
  app_name                  = var.app_name
  vpc_id                    = module.networking.vpc_id
  subnet_ids                = module.networking.private_subnet_ids
  alb_sg_id                 = module.alb.alb_sg_id
  worker_target_group_arn   = module.alb.api_target_group_arn
  messages_target_group_arn = module.alb.messages_target_group_arn
  listener_arn              = module.alb.https_listener_arn
  region                    = var.region
  worker_image              = var.worker_image
  static_ip_image           = var.static_ip_image
  messages_image            = var.messages_image
  app_env                   = var.app_env
  db_endpoint               = module.rds.db_endpoint
  db_password               = var.db_password
  sync_base                 = "http://static.${var.app_name}.local:8000/sync"
  messages_table            = module.chat.table_name
  messages_table_arn        = module.chat.table_arn
  appsync_events_url        = module.chat.events_url
  appsync_api_arn           = module.chat.api_arn
  coc_api_token             = var.coc_api_token
  google_client_id          = var.google_client_id
  google_client_secret      = var.google_client_secret
  depends_on                = [module.alb]
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

module "chat" {
  source          = "../../modules/chat"
  app_name        = var.app_name
  domain_name     = var.chat_domain_name
  certificate_arn = var.chat_certificate_arn
}
