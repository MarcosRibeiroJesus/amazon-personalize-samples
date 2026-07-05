# CloudWatch Log Group for API Gateway
resource "aws_cloudwatch_log_group" "api_gateway" {
  name              = "/aws/apigateway/${var.project_name}-${var.environment}"
  retention_in_days = 7

  tags = {
    Name = "${var.project_name}-api-gateway-logs"
  }
}

# CloudWatch Log Group for Lambda - Recommendation API
resource "aws_cloudwatch_log_group" "lambda_recommendation" {
  name              = "/aws/lambda/${var.project_name}-recommendation-api-${var.environment}"
  retention_in_days = 7

  tags = {
    Name = "${var.project_name}-recommendation-api-logs"
  }
}

# CloudWatch Log Group for Lambda - Event Stream
resource "aws_cloudwatch_log_group" "lambda_event_stream" {
  name              = "/aws/lambda/${var.project_name}-event-stream-${var.environment}"
  retention_in_days = 7

  tags = {
    Name = "${var.project_name}-event-stream-logs"
  }
}

# CloudWatch Alarm - Recommendation Lambda Errors
resource "aws_cloudwatch_metric_alarm" "lambda_recommendation_errors" {
  alarm_name          = "${var.project_name}-recommendation-lambda-errors"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Triggers when Recommendation Lambda has errors"

  dimensions = {
    FunctionName = aws_lambda_function.recommendation_api.function_name
  }
}

# CloudWatch Alarm - Event Stream Lambda Errors
resource "aws_cloudwatch_metric_alarm" "lambda_event_stream_errors" {
  alarm_name          = "${var.project_name}-event-stream-lambda-errors"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Triggers when Event Stream Lambda has errors"

  dimensions = {
    FunctionName = aws_lambda_function.event_stream.function_name
  }
}

# CloudWatch Alarm - Kinesis Iterator Age
resource "aws_cloudwatch_metric_alarm" "kinesis_iterator_age" {
  alarm_name          = "${var.project_name}-kinesis-iterator-age"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "GetRecords.IteratorAgeMilliseconds"
  namespace           = "AWS/Kinesis"
  period              = 300
  statistic           = "Maximum"
  threshold           = 60000  # 1 minute
  alarm_description   = "Triggers when Kinesis iterator age is high"

  dimensions = {
    StreamName = aws_kinesis_stream.user_events.name
  }
}
