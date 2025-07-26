output "chat_table_name" {
  value = aws_dynamodb_table.chat.name
}

output "chat_table_arn" {
  value = aws_dynamodb_table.chat.arn
}

output "chat_table_stream_arn" {
  value = aws_dynamodb_table.chat.stream_arn
}
