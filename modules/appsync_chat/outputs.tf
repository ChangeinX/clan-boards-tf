output "api_url_wss" {
  value = aws_cloudformation_stack.chat_api.outputs["RealTimeUrl"]
}

output "api_url_https" {
  value = aws_cloudformation_stack.chat_api.outputs["GraphQLUrl"]
}

output "table_name" {
  value = aws_dynamodb_table.chat_history.name
}

output "region" {
  value = var.region
}
