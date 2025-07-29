output "alb_dns_name" {
  value = module.alb.alb_dns_name
}

output "db_endpoint" {
  value = module.rds.db_endpoint
}

output "nat_eip" {
  value = module.nat_gateway.nat_eip
}

output "nat_eip_allocation_id" {
  value = module.nat_gateway.nat_eip_allocation_id
}

output "nat_gateway_id" {
  value = module.nat_gateway.nat_gateway_id
}

output "frontend_bucket" {
  value = module.frontend.bucket_name
}

output "frontend_url" {
  value = module.frontend.website_endpoint
}

output "frontend_distribution" {
  value = module.frontend.distribution_domain_name
}

output "frontend_distribution_id" {
  value = module.frontend.distribution_id
}

output "chat_table_name" {
  value = module.chat.chat_table_name
}

output "chat_table_stream_arn" {
  value = module.chat.chat_table_stream_arn
}

output "welcome_bucket" {
  value = module.welcome.bucket_name
}

output "welcome_distribution" {
  value = module.welcome.distribution_domain_name
}

output "welcome_distribution_id" {
  value = module.welcome.distribution_id
}
