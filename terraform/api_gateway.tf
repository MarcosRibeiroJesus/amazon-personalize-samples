# API Gateway REST API
resource "aws_api_gateway_rest_api" "recommendation_api" {
  name        = "${var.project_name}-recommendation-api-${var.environment}"
  description = "Magic Movie Machine Recommendation API"

  tags = {
    Name = "${var.project_name}-recommendation-api"
  }
}

# API Gateway Resource - /recommendations
resource "aws_api_gateway_resource" "recommendations" {
  rest_api_id = aws_api_gateway_rest_api.recommendation_api.id
  parent_id   = aws_api_gateway_rest_api.recommendation_api.root_resource_id
  path_part   = "recommendations"
}

# API Gateway Method - GET /recommendations
resource "aws_api_gateway_method" "get_recommendations" {
  rest_api_id      = aws_api_gateway_rest_api.recommendation_api.id
  resource_id      = aws_api_gateway_resource.recommendations.id
  http_method      = "GET"
  authorization    = "NONE"
  request_parameters = {
    "method.request.querystring.userId"     = true
    "method.request.querystring.numResults" = false
  }
}

# API Gateway Method - POST /recommendations
resource "aws_api_gateway_method" "post_recommendations" {
  rest_api_id   = aws_api_gateway_rest_api.recommendation_api.id
  resource_id   = aws_api_gateway_resource.recommendations.id
  http_method   = "POST"
  authorization = "NONE"
}

# API Gateway Integration - GET
resource "aws_api_gateway_integration" "get_recommendations" {
  rest_api_id             = aws_api_gateway_rest_api.recommendation_api.id
  resource_id             = aws_api_gateway_resource.recommendations.id
  http_method             = aws_api_gateway_method.get_recommendations.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.recommendation_api.invoke_arn
}

# API Gateway Integration - POST
resource "aws_api_gateway_integration" "post_recommendations" {
  rest_api_id             = aws_api_gateway_rest_api.recommendation_api.id
  resource_id             = aws_api_gateway_resource.recommendations.id
  http_method             = aws_api_gateway_method.post_recommendations.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.recommendation_api.invoke_arn
}

# API Gateway Resource - /events
resource "aws_api_gateway_resource" "events" {
  rest_api_id = aws_api_gateway_rest_api.recommendation_api.id
  parent_id   = aws_api_gateway_rest_api.recommendation_api.root_resource_id
  path_part   = "events"
}

# API Gateway Method - POST /events
resource "aws_api_gateway_method" "post_events" {
  rest_api_id   = aws_api_gateway_rest_api.recommendation_api.id
  resource_id   = aws_api_gateway_resource.events.id
  http_method   = "POST"
  authorization = "NONE"
}

# API Gateway Integration - POST /events (Direct Kinesis integration)
resource "aws_api_gateway_integration" "post_events" {
  rest_api_id             = aws_api_gateway_rest_api.recommendation_api.id
  resource_id             = aws_api_gateway_resource.events.id
  http_method             = aws_api_gateway_method.post_events.http_method
  integration_http_method = "POST"
  type                    = "AWS"
  credentials             = aws_iam_role.api_gateway_kinesis_role.arn
  uri                     = "arn:aws:apigateway:${var.aws_region}:kinesis:action/PutRecord"

  request_templates = {
    "application/json" = <<-EOT
    {
      "StreamName": "${aws_kinesis_stream.user_events.name}",
      "Data": "$util.base64Encode($input.body)",
      "PartitionKey": "$input.path('$.userId')"
    }
    EOT
  }
}

# Method response for POST /events
resource "aws_api_gateway_method_response" "post_events_200" {
  rest_api_id = aws_api_gateway_rest_api.recommendation_api.id
  resource_id = aws_api_gateway_resource.events.id
  http_method = aws_api_gateway_method.post_events.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }
}

# Integration response for POST /events
resource "aws_api_gateway_integration_response" "post_events_200" {
  rest_api_id       = aws_api_gateway_rest_api.recommendation_api.id
  resource_id       = aws_api_gateway_resource.events.id
  http_method       = aws_api_gateway_method.post_events.http_method
  status_code       = aws_api_gateway_method_response.post_events_200.status_code
  selection_pattern = ""

  response_templates = {
    "application/json" = jsonencode({
      message = "Event received"
    })
  }
}

# API Gateway Deployment
resource "aws_api_gateway_deployment" "recommendation_api" {
  rest_api_id = aws_api_gateway_rest_api.recommendation_api.id

  depends_on = [
    aws_api_gateway_integration.get_recommendations,
    aws_api_gateway_integration.post_recommendations,
    aws_api_gateway_integration.post_events
  ]
}

# API Gateway Stage
resource "aws_api_gateway_stage" "recommendation_api" {
  deployment_id = aws_api_gateway_deployment.recommendation_api.id
  rest_api_id   = aws_api_gateway_rest_api.recommendation_api.id
  stage_name    = var.environment

  tags = {
    Name = "${var.project_name}-api-stage"
  }
}
