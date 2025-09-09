output "bucket_name" {
  description = "Name of the lambda artifacts S3 bucket"
  value       = aws_s3_bucket.lambda_artifacts.bucket
}

output "bucket_arn" {
  description = "ARN of the lambda artifacts S3 bucket"
  value       = aws_s3_bucket.lambda_artifacts.arn
}