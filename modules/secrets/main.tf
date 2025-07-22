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

resource "aws_secretsmanager_secret" "messages_table" {
  name = "${var.app_name}-messages-table"
}

resource "aws_secretsmanager_secret_version" "messages_table" {
  secret_id     = aws_secretsmanager_secret.messages_table.id
  secret_string = var.messages_table
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
