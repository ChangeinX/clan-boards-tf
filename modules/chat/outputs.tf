output "api_url" {
  value = aws_appsync_graphql_api.chat.uris["GRAPHQL"]
}

output "api_id" {
  value = aws_appsync_graphql_api.chat.id
}

output "table_name" {
  value = aws_dynamodb_table.messages.name
}

output "events_url" {
  value = var.domain_name != null ? "https://${var.domain_name}/graphql" : "https://${aws_appsync_graphql_api.chat.id}.appsync-realtime-api.${data.aws_region.current.name}.amazonaws.com/graphql"
}

output "table_arn" {
  value = aws_dynamodb_table.messages.arn
}

output "event_api_http_endpoint" {
  value = aws_appsync_api.chat_event.uris["EVENT_HTTP"]
}

output "event_api_arn" {
  value = aws_appsync_api.chat_event.arn
}

output "event_namespace" {
  value = aws_appsync_channel_namespace.chat_groups.name
}

output "event_namespace_arn" {
  value = aws_appsync_channel_namespace.chat_groups.arn
}
