provider "aws" {
  region  = var.aws_region
  profile = "iamadmin-general"
}

resource "aws_iam_role" "lambda_role" {
  name = "upload_lambda_role"

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

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Build Go binary
resource "null_resource" "build_lambda" {
  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command     = "cd .. && go build -tags lambda.norpc -o bootstrap main.go"
    working_dir = path.module
    environment = {
      GOOS        = "linux"
      GOARCH      = "amd64"
      CGO_ENABLED = "0"
    }
  }
}

# Zip lambda binary
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "../bootstrap"
  output_path = "../lambda.zip"

  depends_on = [null_resource.build_lambda]
}

resource "aws_lambda_function" "upload_lambda" {
  function_name = "upload-audio"
  filename      = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  handler = "bootstrap"
  runtime = "provided.al2023"
  role    = aws_iam_role.lambda_role.arn

  timeout     = 90
  memory_size = 512

  environment {
    variables = {
      OPENAI_API_KEY = var.openai_api_key
      DB_URL         = var.db_url
    }
  }

  depends_on = [null_resource.build_lambda]
}

# API Gateway HTTP API
resource "aws_apigatewayv2_api" "api" {
  name          = "upload-api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id                 = aws_apigatewayv2_api.api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.upload_lambda.invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "upload_route" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "POST /upload"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

resource "aws_apigatewayv2_route" "expenses_route" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "GET /expenses"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

resource "aws_apigatewayv2_route" "health_route" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "GET /health"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

resource "aws_apigatewayv2_stage" "dev" {
  api_id      = aws_apigatewayv2_api.api.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_lambda_permission" "api_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.upload_lambda.function_name
  principal     = "apigateway.amazonaws.com"
}