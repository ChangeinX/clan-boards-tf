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
