data "archive_file" "lambda" {
  type        = "zip"
  source_file = "${path.module}/cleanup.py"
  output_path = "${path.module}/cleanup.zip"
}

resource "aws_iam_role" "this" {
  name = "${var.app_name}-ecr-cleanup-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "this" {
  name = "${var.app_name}-ecr-cleanup-policy"
  role = aws_iam_role.this.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:DescribeRepositories",
          "ecr:ListImages",
          "ecr:DescribeImages",
          "ecr:BatchDeleteImage"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

resource "aws_lambda_function" "this" {
  function_name    = "${var.app_name}-ecr-cleanup"
  filename         = data.archive_file.lambda.output_path
  source_code_hash = data.archive_file.lambda.output_base64sha256
  role             = aws_iam_role.this.arn
  handler          = "cleanup.lambda_handler"
  runtime          = "python3.11"
  timeout          = 300
}

resource "aws_cloudwatch_event_rule" "weekly" {
  name                = "${var.app_name}-ecr-cleanup-weekly"
  schedule_expression = "rate(7 days)"
}

resource "aws_cloudwatch_event_target" "weekly" {
  rule      = aws_cloudwatch_event_rule.weekly.name
  target_id = "ecr-cleanup"
  arn       = aws_lambda_function.this.arn
}

resource "aws_lambda_permission" "allow_events" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.weekly.arn
}
