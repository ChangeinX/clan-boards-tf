resource "aws_wafv2_web_acl" "this" {
  name  = "${var.app_name}-waf"
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.app_name}-waf"
    sampled_requests_enabled   = true
  }

  rule {
    name     = "allow-options"
    priority = 0

    action {
      allow {}
    }

    statement {
      and_statement {
        statement {
          byte_match_statement {
            search_string = "OPTIONS"
            field_to_match {
              method {}
            }
            positional_constraint = "EXACTLY"
            text_transformation {
              priority = 0
              type     = "NONE"
            }
          }
        }
        statement {
          byte_match_statement {
            search_string = "/api/v1/"
            field_to_match {
              uri_path {}
            }
            positional_constraint = "STARTS_WITH"
            text_transformation {
              priority = 0
              type     = "NONE"
            }
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "allow-options"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWS-AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesCommonRuleSet"
      sampled_requests_enabled   = true
    }
  }
}

locals {
  create_interface_waf = length(var.interface_ipv4_cidrs) + length(var.interface_ipv6_cidrs) > 0
}

resource "aws_wafv2_ip_set" "interface_v4_regional" {
  count              = local.create_interface_waf && length(var.interface_ipv4_cidrs) > 0 ? 1 : 0
  name               = "${var.app_name}-interface-v4-regional"
  scope              = "REGIONAL"
  ip_address_version = "IPV4"
  addresses          = var.interface_ipv4_cidrs
}

resource "aws_wafv2_ip_set" "interface_v6_regional" {
  count              = local.create_interface_waf && length(var.interface_ipv6_cidrs) > 0 ? 1 : 0
  name               = "${var.app_name}-interface-v6-regional"
  scope              = "REGIONAL"
  ip_address_version = "IPV6"
  addresses          = var.interface_ipv6_cidrs
}

resource "aws_wafv2_ip_set" "interface_v4_cf" {
  count              = local.create_interface_waf && length(var.interface_ipv4_cidrs) > 0 ? 1 : 0
  name               = "${var.app_name}-interface-v4-cf"
  scope              = "CLOUDFRONT"
  ip_address_version = "IPV4"
  addresses          = var.interface_ipv4_cidrs
}

resource "aws_wafv2_ip_set" "interface_v6_cf" {
  count              = local.create_interface_waf && length(var.interface_ipv6_cidrs) > 0 ? 1 : 0
  name               = "${var.app_name}-interface-v6-cf"
  scope              = "CLOUDFRONT"
  ip_address_version = "IPV6"
  addresses          = var.interface_ipv6_cidrs
}

resource "aws_wafv2_web_acl" "interface_regional" {
  count = local.create_interface_waf ? 1 : 0
  name  = "${var.app_name}-interface-regional"
  scope = "REGIONAL"

  default_action {
    block {}
  }

  rule {
    name     = "allow-interface"
    priority = 0

    action {
      allow {}
    }

    statement {
      or_statement {
        dynamic "statement" {
          for_each = aws_wafv2_ip_set.interface_v4_regional
          content {
            ip_set_reference_statement { arn = statement.value.arn }
          }
        }
        dynamic "statement" {
          for_each = aws_wafv2_ip_set.interface_v6_regional
          content {
            ip_set_reference_statement { arn = statement.value.arn }
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "allow-interface"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.app_name}-interface-regional"
    sampled_requests_enabled   = true
  }
}

resource "aws_wafv2_web_acl" "interface_cf" {
  count = local.create_interface_waf ? 1 : 0
  name  = "${var.app_name}-interface-cf"
  scope = "CLOUDFRONT"

  default_action {
    block {}
  }

  rule {
    name     = "allow-interface"
    priority = 0

    action {
      allow {}
    }

    statement {
      or_statement {
        dynamic "statement" {
          for_each = aws_wafv2_ip_set.interface_v4_cf
          content {
            ip_set_reference_statement { arn = statement.value.arn }
          }
        }
        dynamic "statement" {
          for_each = aws_wafv2_ip_set.interface_v6_cf
          content {
            ip_set_reference_statement { arn = statement.value.arn }
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "allow-interface"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.app_name}-interface-cf"
    sampled_requests_enabled   = true
  }
}
