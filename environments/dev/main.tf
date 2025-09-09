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

data "aws_caller_identity" "current" {}

module "networking" {
  source   = "../../modules/networking"
  region   = var.region
  app_name = var.app_name
}

module "waf" {
  source               = "../../modules/waf"
  app_name             = var.app_name
  interface_ipv4_cidrs = var.interface_ipv4_cidrs
  interface_ipv6_cidrs = var.interface_ipv6_cidrs
}

module "alb" {
  source            = "../../modules/alb"
  app_name          = var.app_name
  vpc_id            = module.networking.vpc_id
  public_subnet_ids = module.networking.public_subnet_ids
  certificate_arn   = var.certificate_arn
  api_host          = var.api_host
  waf_web_acl_arn   = module.waf.web_acl_arn
}

module "chat" {
  source   = "../../modules/chat"
  app_name = var.app_name
}

module "secrets" {
  source               = "../../modules/secrets"
  app_name             = var.app_name
  region               = var.region
  app_env              = var.app_env
  db_endpoint          = module.rds.db_endpoint
  db_username          = var.db_username
  db_password          = var.db_password
  coc_email            = var.coc_email
  coc_password         = var.coc_password
  chat_table           = module.chat.chat_table_name
  coc_api_token        = var.coc_api_token
  google_client_id     = var.google_client_id
  google_client_secret = var.google_client_secret
  cors_allowed_origins = var.cors_allowed_origins
  session_max_age      = var.session_max_age
  cookie_domain        = var.cookie_domain
  cookie_secure        = var.cookie_secure
}

module "notifications" {
  source                = "../../modules/notifications"
  app_name              = var.app_name
  vapid_secret_name     = var.vapid_secret_name
  chat_table_stream_arn = module.chat.chat_table_stream_arn
}

module "redis" {
  source     = "../../modules/redis"
  app_name   = var.app_name
  vpc_id     = module.networking.vpc_id
  subnet_ids = module.networking.private_subnet_ids
  vpc_cidr   = module.networking.vpc_cidr
}

data "aws_secretsmanager_secret" "openai_moderation" {
  name = "${var.app_env}/openai/moderation"
}

data "aws_secretsmanager_secret" "perspective_api" {
  name = "${var.app_env}/perspective/moderation"
}

module "ecs" {
  source                             = "../../modules/ecs"
  app_name                           = var.app_name
  vpc_id                             = module.networking.vpc_id
  subnet_ids                         = module.networking.private_subnet_ids
  alb_sg_id                          = module.alb.alb_sg_id
  worker_target_group_arn            = module.alb.api_target_group_arn
  messages_target_group_arn          = module.alb.messages_target_group_arn
  user_target_group_arn              = module.alb.user_target_group_arn
  recruiting_target_group_arn        = module.alb.recruiting_target_group_arn
  listener_arn                       = module.alb.https_listener_arn
  region                             = var.region
  worker_image                       = var.worker_image
  user_image                         = var.user_image
  messages_image                     = var.messages_image
  recruiting_image                   = var.recruiting_image
  chat_table_arn                     = module.chat.chat_table_arn
  app_env_arn                        = module.secrets.app_env_arn
  database_url_arn                   = module.secrets.database_url_arn
  database_username_arn              = module.secrets.database_username_arn
  database_password_arn              = module.secrets.database_password_arn
  secret_key_arn                     = module.secrets.secret_key_arn
  aws_region_arn                     = module.secrets.aws_region_arn
  chat_table_secret_arn              = module.secrets.chat_table_secret_arn
  coc_api_token_arn                  = module.secrets.coc_api_token_arn
  google_client_id_arn               = module.secrets.google_client_id_arn
  google_client_secret_arn           = module.secrets.google_client_secret_arn
  jwt_signing_key_arn                = module.secrets.jwt_signing_key_arn
  session_max_age_arn                = module.secrets.session_max_age_arn
  cookie_domain_arn                  = module.secrets.cookie_domain_arn
  cookie_secure_arn                  = module.secrets.cookie_secure_arn
  redis_url_arn                      = module.redis.redis_url_arn
  messages_allowed_origins_arn       = module.secrets.messages_allowed_origins_arn
  user_allowed_origins_arn           = module.secrets.user_allowed_origins_arn
  notifications_allowed_origins_arn  = module.secrets.notifications_allowed_origins_arn
  messages_allowed_origins_name      = module.secrets.messages_allowed_origins_name
  user_allowed_origins_name          = module.secrets.user_allowed_origins_name
  notifications_allowed_origins_name = module.secrets.notifications_allowed_origins_name
  openai_moderation_arn              = data.aws_secretsmanager_secret.openai_moderation.arn
  perspective_api_key_arn            = data.aws_secretsmanager_secret.perspective_api.arn
  notifications_target_group_arn     = module.alb.notifications_target_group_arn
  notifications_image                = var.notifications_image
  notifications_queue_url            = module.notifications.queue_url
  notifications_queue_arn            = module.notifications.queue_arn
  notifications_dlq_url              = module.notifications.dlq_url
  vapid_secret_arn                   = module.notifications.vapid_secret_arn
  depends_on                         = [module.alb]
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
  web_acl_id      = null
}

module "welcome" {
  source          = "../../modules/welcome"
  bucket_name     = var.welcome_bucket_name
  domain_names    = var.welcome_domain_names
  certificate_arn = var.welcome_certificate_arn
  web_acl_id      = null
}

module "ecr_cleanup" {
  source   = "../../modules/ecr_cleanup"
  app_name = var.app_name
}

module "lambda_artifacts" {
  source      = "../../modules/lambda-artifacts"
  bucket_name = var.lambda_artifacts_bucket
}

module "refresh_worker" {
  source                  = "../../modules/refresh-worker"
  app_name                = var.app_name
  app_env                 = var.app_env
  lambda_artifacts_bucket = module.lambda_artifacts.bucket_name
  database_url_arn        = module.secrets.database_url_arn
  redis_url_arn           = module.redis.redis_url_arn
  coc_email_arn           = module.secrets.coc_email_arn
  coc_password_arn        = module.secrets.coc_password_arn
  vpc_id                  = module.networking.vpc_id
  lambda_subnet_ids       = module.networking.private_subnet_ids
  depends_on              = [module.lambda_artifacts]
}
