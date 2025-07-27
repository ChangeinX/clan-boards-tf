resource "aws_secretsmanager_secret" "app_env" {
  name = "${var.app_name}-app-env"
}

resource "aws_secretsmanager_secret_version" "app_env" {
  secret_id     = aws_secretsmanager_secret.app_env.id
  secret_string = var.app_env
}

resource "random_password" "secret_key" {
  length  = 32
  special = false
}

resource "aws_secretsmanager_secret" "secret_key" {
  name = "${var.app_name}-secret-key"
}

resource "aws_secretsmanager_secret_version" "secret_key" {
  secret_id     = aws_secretsmanager_secret.secret_key.id
  secret_string = random_password.secret_key.result
}

resource "aws_secretsmanager_secret" "database_url" {
  name = "${var.app_name}-db-url"
}

resource "aws_secretsmanager_secret_version" "database_url" {
  secret_id     = aws_secretsmanager_secret.database_url.id
  secret_string = "postgresql+psycopg://postgres:${var.db_password}@${var.db_endpoint}:5432/postgres"
}

resource "aws_secretsmanager_secret" "database_username" {
  name = "${var.app_name}-db-username"
}

resource "aws_secretsmanager_secret_version" "database_username" {
  secret_id     = aws_secretsmanager_secret.database_username.id
  secret_string = var.db_username
}

resource "aws_secretsmanager_secret" "database_password" {
  name = "${var.app_name}-db-password"
}

resource "aws_secretsmanager_secret_version" "database_password" {
  secret_id     = aws_secretsmanager_secret.database_password.id
  secret_string = var.db_password
}

resource "aws_secretsmanager_secret" "coc_api_token" {
  name = "${var.app_name}-coc-token"
}

resource "aws_secretsmanager_secret_version" "coc_api_token" {
  secret_id     = aws_secretsmanager_secret.coc_api_token.id
  secret_string = var.coc_api_token
}

resource "aws_secretsmanager_secret" "aws_region" {
  name = "${var.app_name}-aws-region"
}

resource "aws_secretsmanager_secret_version" "aws_region" {
  secret_id     = aws_secretsmanager_secret.aws_region.id
  secret_string = var.region
}

resource "aws_secretsmanager_secret" "chat_table" {
  name = "${var.app_name}-chat-v2-table"
}

resource "aws_secretsmanager_secret_version" "chat_table" {
  secret_id     = aws_secretsmanager_secret.chat_table.id
  secret_string = var.chat_table
}

resource "aws_secretsmanager_secret" "google_client_id" {
  name = "${var.app_name}-google-client-id"
}

resource "aws_secretsmanager_secret_version" "google_client_id" {
  secret_id     = aws_secretsmanager_secret.google_client_id.id
  secret_string = var.google_client_id
}

resource "aws_secretsmanager_secret" "google_client_secret" {
  name = "${var.app_name}-google-client-secret"
}

resource "aws_secretsmanager_secret_version" "google_client_secret" {
  secret_id     = aws_secretsmanager_secret.google_client_secret.id
  secret_string = var.google_client_secret
}

resource "aws_secretsmanager_secret" "messages_allowed_origins" {
  name = "${var.app_name}-messages-allowed-origins"
}

resource "aws_secretsmanager_secret_version" "messages_allowed_origins" {
  secret_id     = aws_secretsmanager_secret.messages_allowed_origins.id
  secret_string = join(",", var.messages_allowed_origins)
}

resource "aws_secretsmanager_secret" "user_allowed_origins" {
  name = "${var.app_name}-user-allowed-origins"
}

resource "aws_secretsmanager_secret_version" "user_allowed_origins" {
  secret_id     = aws_secretsmanager_secret.user_allowed_origins.id
  secret_string = join(",", var.user_allowed_origins)
}

resource "aws_secretsmanager_secret" "notifications_allowed_origins" {
  name = "${var.app_name}-notifications-allowed-origins"
}

resource "aws_secretsmanager_secret_version" "notifications_allowed_origins" {
  secret_id     = aws_secretsmanager_secret.notifications_allowed_origins.id
  secret_string = join(",", var.notifications_allowed_origins)
}
