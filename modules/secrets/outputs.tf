output "app_env_arn" {
  value = aws_secretsmanager_secret.app_env.arn
}

output "secret_key_arn" {
  value = aws_secretsmanager_secret.secret_key.arn
}

output "database_url_arn" {
  value = aws_secretsmanager_secret.database_url.arn
}

output "coc_api_token_arn" {
  value = aws_secretsmanager_secret.coc_api_token.arn
}

output "aws_region_arn" {
  value = aws_secretsmanager_secret.aws_region.arn
}

output "messages_table_secret_arn" {
  value = aws_secretsmanager_secret.messages_table.arn
}

output "google_client_id_arn" {
  value = aws_secretsmanager_secret.google_client_id.arn
}

output "google_client_secret_arn" {
  value = aws_secretsmanager_secret.google_client_secret.arn
}
