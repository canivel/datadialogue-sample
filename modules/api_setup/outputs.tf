output "api_gateway_url" {
  description = "URL endpoint of the API Gateway"
  value       = aws_api_gateway_deployment.deployment.invoke_url
}

output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.this.arn
}

output "cognito_user_pool_id" {
  description = "ID of the Cognito User Pool"
  value       = aws_cognito_user_pool.this.id
}