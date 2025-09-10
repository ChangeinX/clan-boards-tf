
output "message_service_repository_url" {
  value = aws_ecr_repository.message_service.repository_url
}

output "message_service_repository_arn" {
  value = aws_ecr_repository.message_service.arn
}

output "user_service_repository_url" {
  value = aws_ecr_repository.user_service.repository_url
}

output "user_service_repository_arn" {
  value = aws_ecr_repository.user_service.arn
}

output "notifications_service_repository_url" {
  value = aws_ecr_repository.notifications_service.repository_url
}

output "notifications_service_repository_arn" {
  value = aws_ecr_repository.notifications_service.arn
}

output "recruiting_repository_url" {
  value = aws_ecr_repository.recruiting.repository_url
}

output "recruiting_repository_arn" {
  value = aws_ecr_repository.recruiting.arn
}

output "clan_data_repository_url" {
  value = aws_ecr_repository.clan_data.repository_url
}

output "clan_data_repository_arn" {
  value = aws_ecr_repository.clan_data.arn
}