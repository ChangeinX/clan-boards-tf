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
