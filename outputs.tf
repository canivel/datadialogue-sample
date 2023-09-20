output "api_gateway_url" {
  value       = module.api_setup.api_gateway_url
  description = "URL endpoint of the API Gateway"
}

output "lambda_function_arn" {
  value       = module.api_setup.lambda_function_arn
  description = "ARN of the Lambda function"
}

output "cognito_user_pool_id" {
  value       = module.api_setup.cognito_user_pool_id
  description = "ID of the Cognito User Pool"
}

output "s3_bucket_name" {
  value       = module.data_pipeline.s3_bucket_name
  description = "Name of the S3 bucket"
}