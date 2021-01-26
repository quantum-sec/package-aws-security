output "trail_arn" {
  description = "The ARN of the cloudtrail trail."
  value       = aws_cloudtrail.cloudtrail.arn
}

output "trail_name" {
  description = "The name of the cloudtrail trail."
  value       = aws_cloudtrail.cloudtrail.name
}

output "s3_bucket_name" {
  description = "The name of the S3 bucket where cloudtrail logs are delivered."
  value       = local.create_s3_bucket ? module.bucket[0].id : null
}

output "s3_bucket_arn" {
  description = "The ARN of the S3 bucket where cloudtrail logs are delivered."
  value       = local.create_s3_bucket ? module.bucket[0].arn : null
}

output "s3_access_logging_bucket_arn" {
  description = "The ARN of the S3 bucket where server access logs are delivered."
  value       = local.create_s3_bucket ? module.bucket[0].bucket_logging_arn : null
}

output "kms_key_arn" {
  description = "The ARN of the KMS key used by the S3 bucket to encrypt cloudtrail logs."
  value       = local.kms_key_arn
}