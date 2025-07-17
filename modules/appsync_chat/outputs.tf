output "api_url_wss" {
  value = aws_appsync_event_api.chat.uris["real_time_url"]
}

output "api_url_https" {
  value = aws_appsync_event_api.chat.uris["graphql_url"]
}

output "table_name" {
  value = aws_dynamodb_table.chat_history.name
}

output "region" {
  value = var.region
}
