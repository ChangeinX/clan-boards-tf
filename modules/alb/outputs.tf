output "alb_dns_name" {
  value = aws_lb.this.dns_name
}

output "alb_sg_id" {
  value = aws_security_group.alb.id
}

output "alb_arn" {
  value = aws_lb.this.arn
}

output "target_group_arn" {
  value = aws_lb_target_group.app.arn
}
output "https_listener_arn" {
  value = aws_lb_listener.https.arn
}

output "api_target_group_arn" {
  value = aws_lb_target_group.api.arn
}

output "messages_target_group_arn" {
  value = aws_lb_target_group.messages.arn
}

output "notifications_target_group_arn" {
  value = aws_lb_target_group.notifications.arn
}

output "user_target_group_arn" {
  value = aws_lb_target_group.user.arn
}

