resource "aws_cloudwatch_event_rule" "refresh_schedule" {
  name                = "${var.app_name}-refresh-worker-schedule"
  description         = "Triggers the refresh worker Lambda every 2 minutes"
  schedule_expression = var.schedule_expression
}

resource "aws_cloudwatch_event_target" "refresh_schedule" {
  rule      = aws_cloudwatch_event_rule.refresh_schedule.name
  target_id = "refresh-worker-target"
  arn       = aws_lambda_function.this.arn
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.refresh_schedule.arn
}

# CloudWatch Alarms for monitoring
resource "aws_cloudwatch_metric_alarm" "error_rate" {
  alarm_name          = "${var.app_name}-refresh-worker-error-rate"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Sum"
  threshold           = "5"
  alarm_description   = "Lambda function error rate is too high"
  alarm_actions       = []

  dimensions = {
    FunctionName = aws_lambda_function.this.function_name
  }
}

resource "aws_cloudwatch_metric_alarm" "duration" {
  alarm_name          = "${var.app_name}-refresh-worker-duration"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Duration"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Average"
  threshold           = "240000"
  alarm_description   = "Lambda function duration approaching timeout"
  alarm_actions       = []

  dimensions = {
    FunctionName = aws_lambda_function.this.function_name
  }
}

resource "aws_cloudwatch_metric_alarm" "no_invocations" {
  alarm_name          = "${var.app_name}-refresh-worker-no-invocations"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "3"
  metric_name         = "Invocations"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "Lambda function has not been invoked recently"
  alarm_actions       = []
  treat_missing_data  = "breaching"

  dimensions = {
    FunctionName = aws_lambda_function.this.function_name
  }
}