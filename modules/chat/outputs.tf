output "api_url" {
  value = aws_appsync_graphql_api.chat.uris["GRAPHQL"]
}

output "api_id" {
  value = aws_appsync_graphql_api.chat.id
}

output "table_name" {
  value = aws_dynamodb_table.messages.name
}
