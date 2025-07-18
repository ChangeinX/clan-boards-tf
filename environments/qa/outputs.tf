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

output "chat_api_url" {
  value = module.chat.api_url
}

output "chat_table_name" {
  value = module.chat.table_name
}

output "chat_events_url" {
  value = module.chat.events_url
}

output "event_api_http_endpoint" {
  value = module.chat.event_api_http_endpoint
}

output "event_api_arn" {
  value = module.chat.event_api_arn
}

output "event_namespace" {
  value = module.chat.event_namespace
}

output "event_namespace_arn" {
  value = module.chat.event_namespace_arn
}
