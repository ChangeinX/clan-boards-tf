output "lambda_function_name" {
  description = "Name of the cleanup Lambda function"
  value       = aws_lambda_function.this.function_name
}
