terraform {
  backend "s3" {
    encrypt = true
  }
}
data "aws_caller_identity" "current" {}

locals {
  application_name = "fastapi-app"
}

provider "aws" {
  region = var.region
}


resource "aws_iam_role" "lambda_role" {
  name = "lambda_textract_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_policy" "textract_policy" {
  name        = "textract_policy"
  description = "Allows Lambda to access Textract, Rekoginition"
  
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow"
      Action   = ["textract:DetectDocumentText","rekognition:DetectText"]
      Resource = "*"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "attach_textract_policy" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.textract_policy.arn
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "archive_file" "zip_lambda_python_code" {
  type        = "zip"
  source_dir  = "${path.module}/src/"
  output_path = "${path.module}/deploy/textetract.zip"
}

resource "aws_lambda_function" "textract_lambda" {
  function_name    = "textract_lambda"
  role            = aws_iam_role.lambda_role.arn
  handler         = "app.lambda_handler"
  runtime         = "python3.8"
  filename        = "${path.module}/deploy/textetract.zip"
  source_code_hash = data.archive_file.zip_lambda_python_code.output_base64sha256
  timeout         = 10
}


# Define API Gateway
resource "aws_api_gateway_rest_api" "textract_api" {
  name        = "textract_api"
  description = "API for extracting text using AWS Textract"
}

# Create a resource (e.g., /extract)
resource "aws_api_gateway_resource" "extract" {
  rest_api_id = aws_api_gateway_rest_api.textract_api.id
  parent_id   = aws_api_gateway_rest_api.textract_api.root_resource_id
  path_part   = "extract"
}

# Create the HTTP method (POST)
resource "aws_api_gateway_method" "extract_post" {
  rest_api_id   = aws_api_gateway_rest_api.textract_api.id
  resource_id   = aws_api_gateway_resource.extract.id
  http_method   = "POST"
  authorization = "NONE"
}

# Integrate API Gateway with Lambda
resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id = aws_api_gateway_rest_api.textract_api.id
  resource_id = aws_api_gateway_resource.extract.id
  http_method = aws_api_gateway_method.extract_post.http_method
  integration_http_method = "POST"
  type = "AWS_PROXY"
  uri = aws_lambda_function.textract_lambda.invoke_arn
}

# Deploy API Gateway
resource "aws_api_gateway_deployment" "deployment" {
  depends_on = [aws_api_gateway_integration.lambda_integration]
  rest_api_id = aws_api_gateway_rest_api.textract_api.id
  stage_name  = "prod"
}

# Grant API Gateway permission to invoke Lambda
resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.textract_lambda.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.textract_api.execution_arn}/*/*"
}

# Output the API Gateway endpoint
output "api_gateway_url" {
  value = "${aws_api_gateway_deployment.deployment.invoke_url}/extract"
}
