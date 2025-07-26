output "queue_url" {
  value = aws_sqs_queue.outbox.url
}

output "queue_arn" {
  value = aws_sqs_queue.outbox.arn
}

output "dlq_url" {
  value = aws_sqs_queue.dlq.url
}

output "vapid_secret_arn" {
  value = data.aws_secretsmanager_secret.vapid.arn
}
