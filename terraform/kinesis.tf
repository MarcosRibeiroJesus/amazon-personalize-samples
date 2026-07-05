# Kinesis Data Stream for user events
resource "aws_kinesis_stream" "user_events" {
  name             = "${var.project_name}-user-events-${var.environment}"
  shard_count      = var.kinesis_shard_count
  retention_period = 24

  tags = {
    Name = "${var.project_name}-user-events-stream"
  }
}

# Event source mapping for Lambda to consume from Kinesis
resource "aws_lambda_event_source_mapping" "kinesis_to_lambda" {
  event_source_arn  = aws_kinesis_stream.user_events.arn
  function_name     = aws_lambda_function.event_stream.arn
  enabled           = true
  starting_position = "LATEST"
  batch_size        = 100

  depends_on = [
    aws_iam_role_policy.lambda_event_stream_policy,
    aws_lambda_function.event_stream
  ]
}
