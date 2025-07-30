output "redis_endpoint" {
  value = aws_elasticache_cluster.this.cache_nodes[0].address
}

output "redis_url_arn" {
  value = aws_secretsmanager_secret.redis_url.arn
}
