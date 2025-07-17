output "ecs_sg_id" {
  value = aws_security_group.ecs.id
}

output "task_role_arn" {
  value = aws_iam_role.task_with_db.arn
}
