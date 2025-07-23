output "table_name" {
  value = aws_dynamodb_table.messages.name
}
output "table_arn" {
  value = aws_dynamodb_table.messages.arn
}

output "v2_table_name" {
  value = aws_dynamodb_table.chat.name
}

output "v2_table_arn" {
  value = aws_dynamodb_table.chat.arn
}
