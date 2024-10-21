# Provider configuration
provider "aws" {
  region = "***"
}

# 1. S3 Bucket for Static Website (Frontend)
resource "aws_s3_bucket" "frontend" {
  bucket = "***-frontend-bucket-unique-123456"
}

resource "aws_s3_bucket_object" "index" {
  bucket       = aws_s3_bucket.frontend.bucket
  key          = "index.html"
  source       = "***"
  content_type = "text/html"
}

# Configure the S3 bucket as a static website
resource "aws_s3_bucket_website_configuration" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  index_document {
    suffix = "index.html"
  }
}

# 2. IAM Role for Lambda Execution
resource "aws_iam_role" "lambda_exec" {
  name = "***"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

# 3. Lambda Function (Backend)
resource "aws_lambda_function" "backend" {
  function_name = "***"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.9"
  filename      = "***"

  environment {
    variables = {
      DYNAMODB_TABLE = aws_dynamodb_table.app_data.name
    }
  }
}

# Permission for API Gateway to invoke Lambda
resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "***"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.backend.function_name
  principal     = "apigateway.amazonaws.com"
}

# 4. API Gateway to Expose Lambda (Backend API)
resource "aws_api_gateway_rest_api" "backend_api" {
  name = "***"
}

resource "aws_api_gateway_resource" "lambda_resource" {
  rest_api_id = aws_api_gateway_rest_api.backend_api.id
  parent_id   = aws_api_gateway_rest_api.backend_api.root_resource_id
  path_part   = "backend"
}

resource "aws_api_gateway_method" "get_method" {
  rest_api_id   = aws_api_gateway_rest_api.backend_api.id
  resource_id   = aws_api_gateway_resource.lambda_resource.id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.backend_api.id
  resource_id             = aws_api_gateway_resource.lambda_resource.id
  http_method             = aws_api_gateway_method.get_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.backend.invoke_arn

  depends_on = [aws_lambda_function.backend]
}

# 5. API Gateway Method Response
resource "aws_api_gateway_method_response" "method_response" {
  rest_api_id = aws_api_gateway_rest_api.backend_api.id
  resource_id = aws_api_gateway_resource.lambda_resource.id
  http_method = aws_api_gateway_method.get_method.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
  }
}

# 6. API Gateway Integration Response
resource "aws_api_gateway_integration_response" "integration_response" {
  rest_api_id = aws_api_gateway_rest_api.backend_api.id
  resource_id = aws_api_gateway_resource.lambda_resource.id
  http_method = aws_api_gateway_method.get_method.http_method
  status_code = aws_api_gateway_method_response.method_response.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
    "method.response.header.Access-Control-Allow-Headers" = "'*'"
    "method.response.header.Access-Control-Allow-Methods" = "'OPTIONS,GET'"
  }

  depends_on = [aws_api_gateway_integration.lambda_integration]
}

# API Gateway Deployment
resource "aws_api_gateway_deployment" "api" {
  rest_api_id = aws_api_gateway_rest_api.backend_api.id
  stage_name  = "prod"

  depends_on = [
    aws_api_gateway_method.get_method,
    aws_api_gateway_integration.lambda_integration,
    aws_api_gateway_method_response.method_response,
    aws_api_gateway_integration_response.integration_response
  ]
}

# Output API Gateway URL
output "api_gateway_url" {
  value       = "https://${aws_api_gateway_rest_api.backend_api.id}.execute-api.***.amazonaws.com/prod/backend"
  description = "API Gateway Invoke URL"
}

# 7. DynamoDB Table for Data Storage
resource "aws_dynamodb_table" "app_data" {
  name         = "***" 
  billing_mode = "PAY_PER_REQUEST"

  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }
}

# IAM Role Policy for Lambda
resource "aws_iam_role_policy" "lambda_exec_policy" {
  role = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "dynamodb:PutItem",
          "dynamodb:Scan",
          "dynamodb:GetItem",
          "dynamodb:UpdateItem"
        ],
        Resource = aws_dynamodb_table.app_data.arn
      },
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}