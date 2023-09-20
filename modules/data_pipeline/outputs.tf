output "athena_results_bucket_name" {
  value       = aws_s3_bucket.athena_results.bucket
  description = "The name of the Athena results S3 bucket."
}

output "glue_database_name" {
  value       = aws_glue_catalog_database.this.name
  description = "The name of the Glue catalog database."
}

output "s3_bucket_name" {
  description = "Name of the primary S3 bucket"
  value       = aws_s3_bucket.this.bucket
}
