output "app_env_arn" {
  value = aws_secretsmanager_secret.app_env.arn
}

output "secret_key_arn" {
  value = aws_secretsmanager_secret.secret_key.arn
}

output "database_url_arn" {
  value = aws_secretsmanager_secret.database_url.arn
}

output "database_username_arn" {
  value = aws_secretsmanager_secret.database_username.arn
}

output "database_password_arn" {
  value = aws_secretsmanager_secret.database_password.arn
}

output "coc_api_token_arn" {
  value = aws_secretsmanager_secret.coc_api_token.arn
}

output "aws_region_arn" {
  value = aws_secretsmanager_secret.aws_region.arn
}

output "chat_table_secret_arn" {
  value = aws_secretsmanager_secret.chat_table.arn
}

output "google_client_id_arn" {
  value = aws_secretsmanager_secret.google_client_id.arn
}

output "google_client_secret_arn" {
  value = aws_secretsmanager_secret.google_client_secret.arn
}

output "messages_allowed_origins_arn" {
  value = aws_secretsmanager_secret.messages_allowed_origins.arn
}

output "user_allowed_origins_arn" {
  value = aws_secretsmanager_secret.user_allowed_origins.arn
}

output "messages_allowed_origins_name" {
  value = aws_secretsmanager_secret.messages_allowed_origins.name
}

output "user_allowed_origins_name" {
  value = aws_secretsmanager_secret.user_allowed_origins.name
}

output "notifications_allowed_origins_arn" {
  value = aws_secretsmanager_secret.notifications_allowed_origins.arn
}

output "notifications_allowed_origins_name" {
  value = aws_secretsmanager_secret.notifications_allowed_origins.name
}

output "jwt_signing_key_arn" {
  value = aws_secretsmanager_secret.jwt_signing_key.arn
}

output "session_max_age_arn" {
  value = aws_secretsmanager_secret.session_max_age.arn
}

output "cookie_domain_arn" {
  value = aws_secretsmanager_secret.cookie_domain.arn
}

output "cookie_secure_arn" {
  value = aws_secretsmanager_secret.cookie_secure.arn
}

output "coc_email_arn" {
  value = aws_secretsmanager_secret.coc_email.arn
}

output "coc_password_arn" {
  value = aws_secretsmanager_secret.coc_password.arn
}
