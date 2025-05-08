output "full_bucket_name" {
  value = aws_s3_bucket.main.id
}

output "s3_website_endpoint" {
  value = aws_s3_bucket_website_configuration.default.website_endpoint
}

output "logging_bucket_name" {
  value = var.enable_logging ? aws_s3_bucket.logging[0].id : null
}

output "aws_canonical_user_id" {
  value = data.aws_canonical_user_id.current.id
}