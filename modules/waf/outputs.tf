output "web_acl_arn" {
  value = aws_wafv2_web_acl.this.arn
}

output "interface_regional_web_acl_arn" {
  value = length(aws_wafv2_web_acl.interface_regional) > 0 ? aws_wafv2_web_acl.interface_regional[0].arn : null
}

output "interface_cloudfront_web_acl_arn" {
  value = length(aws_wafv2_web_acl.interface_cf) > 0 ? aws_wafv2_web_acl.interface_cf[0].arn : null
}
