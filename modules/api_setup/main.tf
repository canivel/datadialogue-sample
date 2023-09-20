//SECRET

# Resources that are not part of any module, if any
# For instance, your Secrets Manager resource might be here if it's not part of a module:

resource "random_pet" "secret_name" {
  length    = 2
  separator = "-"
}

resource "aws_secretsmanager_secret" "openai_api" {
  name = "openai-api-key-${random_pet.secret_name.id}"
}

//LAMBDA


resource "aws_lambda_function" "this" {
  function_name = "DataDialogueLambdaFunction"
  role          = aws_iam_role.lambda_exec.arn
  package_type  = "Image"
  image_uri     = var.image_uri_var
  timeout       = 60

  environment {
    variables = {
      GLUE_DB_NAME             = var.glue_database_name
      ATHENA_S3_RESULTS_BUCKET = var.athena_results_bucket_name
      OPENAI_API_SECRET_NAME    = aws_secretsmanager_secret.openai_api.arn
    }
  }
}


resource "aws_iam_role" "lambda_exec" {
  name = "lambda_exec_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
        Effect = "Allow",
        Sid    = ""
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_exec_policy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda_exec.name
}

resource "aws_iam_policy" "secrets_access_policy" {
  name        = "SecretsAccessPolicy"
  description = "Allows lambda to access Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action   = "secretsmanager:GetSecretValue",
        Effect   = "Allow",
        Resource = "${aws_secretsmanager_secret.openai_api.arn}"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_secrets_access" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.secrets_access_policy.arn
}

resource "aws_iam_policy" "lambda_athena_access" {
  name        = "LambdaAthenaAccessPolicy"
  description = "Allows lambda to access Athena, Glue, and S3"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "athena:*",
        Effect = "Allow",
        Resource = "*"
      },
      {
        Action = "glue:*",
        Effect = "Allow",
        Resource = "*"
      },
      {
        Action = "s3:*",
        Effect = "Allow",
        Resource = "*"
      },
    ]
  })
}


resource "aws_iam_role_policy_attachment" "lambda_athena_access" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_athena_access.arn
}

locals {
  split_uri        = split(".", split("/", var.image_uri_var)[0])
  account_id       = local.split_uri[0]
  region           = local.split_uri[3]
  repository_name  = split(":", split("/", var.image_uri_var)[1])[0]
  ecr_arn          = "arn:aws:ecr:${local.region}:${local.account_id}:repository/${local.repository_name}"
}
resource "aws_iam_policy" "lambda_ecr_access" {
  name        = "LambdaECRAccessPolicy"
  description = "Allows lambda to pull images from ECR"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action   = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability"
        ],
        Effect   = "Allow",
        Resource = local.ecr_arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_ecr_access" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_ecr_access.arn
}



// COGNITO

resource "aws_cognito_user_pool" "this" {
  name = "DataDialogueUserPool"

  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_symbols   = true
    require_uppercase = true
  }
}

resource "aws_cognito_user_pool_client" "this" {
  name         = "DataDialogueUserPoolClient"
  user_pool_id = aws_cognito_user_pool.this.id
  generate_secret = true
}

// API GATEWAY

resource "aws_api_gateway_rest_api" "this" {
  name = "DataDialogueAPI"
  description = "API for Data Dialogue"
}

resource "aws_api_gateway_authorizer" "cognito_authorizer" {
  name          = "CognitoUserPoolAuthorizer"
  type          = "COGNITO_USER_POOLS"
  rest_api_id   = aws_api_gateway_rest_api.this.id
  provider_arns = [aws_cognito_user_pool.this.arn]
}

resource "aws_api_gateway_resource" "resource" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_rest_api.this.root_resource_id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "method" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = aws_api_gateway_resource.resource.id
  http_method   = "ANY"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito_authorizer.id
}

resource "aws_api_gateway_integration" "integration" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.resource.id
  http_method = aws_api_gateway_method.method.http_method
  
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.this.invoke_arn
}

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.this.execution_arn}/*/*"
}

resource "aws_api_gateway_deployment" "deployment" {
  depends_on = [aws_api_gateway_integration.integration]
  
  rest_api_id = aws_api_gateway_rest_api.this.id
  stage_name  = "prod"
  
  lifecycle {
    create_before_destroy = true
  }
}

// APIGW CORS

resource "aws_api_gateway_method" "options" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = aws_api_gateway_resource.resource.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "options" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.resource.id
  http_method = aws_api_gateway_method.options.http_method
  
  type = "MOCK"
}

resource "aws_api_gateway_method_response" "response_200" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.resource.id
  http_method = aws_api_gateway_method.options.http_method
  status_code = "200"
  
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "false"
    "method.response.header.Access-Control-Allow-Methods" = "false"
    "method.response.header.Access-Control-Allow-Origin"  = "false"
  }
}

resource "aws_api_gateway_integration_response" "options" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.resource.id
  http_method = aws_api_gateway_method.options.http_method
  status_code = "200"
  
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token,X-Amz-User-Agent'"
    "method.response.header.Access-Control-Allow-Methods" = "'*'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }

  depends_on = [aws_api_gateway_integration.options]
}
