output "alb_dns_name" {
  value = module.alb.alb_dns_name
}

output "db_endpoint" {
  value = module.rds.db_endpoint
}
