output "state_bucket" {
  value = aws_s3_bucket.state.id
}

output "state_table" {
  value = aws_dynamodb_table.lock.name
}
