data "aws_secretsmanager_secret" "vapid" {
  name = var.vapid_secret_name
}

resource "aws_sqs_queue" "dlq" {
  name = "${var.app_name}-notifications-dlq"
}

resource "aws_sqs_queue" "outbox" {
  name                       = "${var.app_name}-notifications-outbox"
  visibility_timeout_seconds = 30
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = 5
  })
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

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda_sqs" {
  name = "${var.app_name}-lambda-sqs"
  role = aws_iam_role.lambda.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = "sqs:SendMessage",
      Resource = aws_sqs_queue.outbox.arn
    }]
  })
}

data "archive_file" "lambda" {
  type        = "zip"
  source_file = "${path.module}/lambda/index.js"
  output_path = "${path.module}/lambda.zip"
}

resource "aws_lambda_function" "stream_to_queue" {
  function_name    = "${var.app_name}-chat-stream"
  role             = aws_iam_role.lambda.arn
  handler          = "index.handler"
  runtime          = "nodejs18.x"
  filename         = data.archive_file.lambda.output_path
  source_code_hash = data.archive_file.lambda.output_base64sha256
  environment {
    variables = {
      OUTBOX_QUEUE_URL = aws_sqs_queue.outbox.url
    }
  }
}

resource "aws_lambda_event_source_mapping" "chat_stream" {
  event_source_arn  = var.chat_table_stream_arn
  function_name     = aws_lambda_function.stream_to_queue.arn
  starting_position = "LATEST"
}

resource "aws_cloudwatch_metric_alarm" "queue_backlog" {
  alarm_name          = "${var.app_name}-notifications-queue-backlog"
  namespace           = "AWS/SQS"
  metric_name         = "ApproximateAgeOfOldestMessage"
  dimensions          = { QueueName = aws_sqs_queue.outbox.name }
  statistic           = "Maximum"
  period              = 60
  evaluation_periods  = 1
  threshold           = 300
  comparison_operator = "GreaterThanThreshold"
}

resource "aws_cloudwatch_metric_alarm" "lambda_error_rate" {
  alarm_name          = "${var.app_name}-notifications-error-rate"
  evaluation_periods  = 1
  threshold           = 2
  comparison_operator = "GreaterThanThreshold"
  metric_query {
    id          = "e1"
    expression  = "100 * errors / invocations"
    label       = "ErrorRate"
    return_data = true
  }
  metric_query {
    id = "errors"
    metric {
      metric_name = "Errors"
      namespace   = "AWS/Lambda"
      period      = 60
      stat        = "Sum"
      dimensions = {
        FunctionName = aws_lambda_function.stream_to_queue.function_name
      }
    }
  }
  metric_query {
    id = "invocations"
    metric {
      metric_name = "Invocations"
      namespace   = "AWS/Lambda"
      period      = 60
      stat        = "Sum"
      dimensions = {
        FunctionName = aws_lambda_function.stream_to_queue.function_name
      }
    }
  }
}

