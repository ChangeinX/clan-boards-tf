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

output "chat_api_wss" {
  value = module.appsync_chat.api_url_wss
}

output "chat_api_https" {
  value = module.appsync_chat.api_url_https
}

output "chat_table" {
  value = module.appsync_chat.table_name
}
