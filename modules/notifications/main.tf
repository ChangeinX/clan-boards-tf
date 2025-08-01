data "aws_secretsmanager_secret" "vapid" {
  name = var.vapid_secret_name
}

data "archive_file" "lambda" {
  type        = "zip"
  source_file = "${path.module}/lambda/index.js"
  output_path = "${path.module}/lambda.zip"
}

resource "aws_lambda_function" "stream" {
  function_name    = "${var.app_name}-chat-stream"
  runtime          = "nodejs20.x"
  handler          = "index.handler"
  role             = aws_iam_role.lambda.arn
  filename         = data.archive_file.lambda.output_path
  source_code_hash = data.archive_file.lambda.output_base64sha256

  environment {
    variables = {
      QUEUE_URL = aws_sqs_queue.outbox.url
    }
  }
}

resource "aws_iam_role" "lambda" {
  name = "${var.app_name}-notifications-lambda"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "lambda_policy" {
  name = "${var.app_name}-lambda"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["sqs:SendMessage"],
        Resource = aws_sqs_queue.outbox.arn
      },
      {
        Effect = "Allow",
        Action = [
          "dynamodb:GetRecords",
          "dynamodb:GetShardIterator",
          "dynamodb:DescribeStream",
          "dynamodb:ListStreams"
        ],
        Resource = var.chat_table_stream_arn
      },
      {
        Effect   = "Allow",
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"],
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

resource "aws_lambda_event_source_mapping" "stream" {
  event_source_arn  = var.chat_table_stream_arn
  function_name     = aws_lambda_function.stream.arn
  starting_position = "TRIM_HORIZON"
}

resource "aws_sqs_queue" "dlq" {
  name = "${var.app_name}-notifications-dlq"
}

resource "aws_sqs_queue" "outbox" {
  name                       = "${var.app_name}-notifications-outbox"
  visibility_timeout_seconds = 30
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn,
    maxReceiveCount     = 5
  })
}

resource "aws_cloudwatch_metric_alarm" "queue_age" {
  alarm_name          = "${var.app_name}-notif-age"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  threshold           = 300
  metric_name         = "ApproximateAgeOfOldestMessage"
  namespace           = "AWS/SQS"
  period              = 60
  statistic           = "Maximum"
  dimensions = {
    QueueName = aws_sqs_queue.outbox.name
  }
}

resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "${var.app_name}-notif-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  threshold           = 2
  metric_query {
    id          = "e1"
    expression  = "m1/m2*100"
    label       = "ErrorRate"
    return_data = true
  }
  metric_query {
    id = "m1"
    metric {
      namespace   = "AWS/Lambda"
      metric_name = "Errors"
      period      = 60
      stat        = "Sum"
      dimensions = {
        FunctionName = aws_lambda_function.stream.function_name
      }
    }
  }
  metric_query {
    id = "m2"
    metric {
      namespace   = "AWS/Lambda"
      metric_name = "Invocations"
      period      = 60
      stat        = "Sum"
      dimensions = {
        FunctionName = aws_lambda_function.stream.function_name
      }
    }
  }
}
