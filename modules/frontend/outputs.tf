output "bucket_name" {
  value = aws_s3_bucket.this.bucket
}

output "website_endpoint" {
  value = aws_s3_bucket.this.website_endpoint
}

output "distribution_domain_name" {
  value = aws_cloudfront_distribution.this.domain_name
}

output "distribution_id" {
  value = aws_cloudfront_distribution.this.id
}
