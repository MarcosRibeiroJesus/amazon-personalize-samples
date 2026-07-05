# Data archive for Lambda functions
data "archive_file" "recommendation_api_zip" {
  type        = "zip"
  output_path = "/tmp/recommendation_api.zip"

  source {
    content  = file("${path.module}/../lambda_functions/recommendation_api.py")
    filename = "lambda_function.py"
  }
}

data "archive_file" "event_stream_zip" {
  type        = "zip"
  output_path = "/tmp/event_stream.zip"

  source {
    content  = file("${path.module}/../lambda_functions/event_stream.py")
    filename = "lambda_function.py"
  }
}

# Lambda function - Recommendation API
resource "aws_lambda_function" "recommendation_api" {
  filename         = data.archive_file.recommendation_api_zip.output_path
  function_name    = "${var.project_name}-recommendation-api-${var.environment}"
  role             = aws_iam_role.lambda_recommendation_role.arn
  handler          = "lambda_function.lambda_handler"
  source_code_hash = data.archive_file.recommendation_api_zip.output_base64sha256
  timeout          = var.lambda_timeout
  memory_size      = var.lambda_memory
  runtime          = "python3.11"

  environment {
    variables = {
      PERSONALIZE_CAMPAIGN_ARN = "arn:aws:personalize:${var.aws_region}:${data.aws_caller_identity.current.account_id}:campaign/placeholder"
      REGION                   = var.aws_region
    }
  }

  tags = {
    Name = "${var.project_name}-recommendation-api"
  }
}

# Lambda function - Event Stream
resource "aws_lambda_function" "event_stream" {
  filename         = data.archive_file.event_stream_zip.output_path
  function_name    = "${var.project_name}-event-stream-${var.environment}"
  role             = aws_iam_role.lambda_event_stream_role.arn
  handler          = "lambda_function.lambda_handler"
  source_code_hash = data.archive_file.event_stream_zip.output_base64sha256
  timeout          = var.lambda_timeout
  memory_size      = var.lambda_memory
  runtime          = "python3.11"

  environment {
    variables = {
      DATASET_GROUP_ARN = "arn:aws:personalize:${var.aws_region}:${data.aws_caller_identity.current.account_id}:dataset-group/placeholder"
      REGION            = var.aws_region
      KINESIS_STREAM    = aws_kinesis_stream.user_events.name
    }
  }

  tags = {
    Name = "${var.project_name}-event-stream"
  }
}

# Lambda permission for API Gateway
resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.recommendation_api.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.recommendation_api.execution_arn}/*/*"
}
