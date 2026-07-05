# IAM Role for Personalize to read from S3
resource "aws_iam_role" "personalize_role" {
  name = "${var.project_name}-personalize-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "personalize.amazonaws.com"
        }
      }
    ]
  })
}

# IAM Policy for Personalize S3 access
resource "aws_iam_role_policy" "personalize_s3_policy" {
  name   = "${var.project_name}-personalize-s3-policy"
  role   = aws_iam_role.personalize_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.personalize_data.arn,
          "${aws_s3_bucket.personalize_data.arn}/*"
        ]
      }
    ]
  })
}

# IAM Role for Lambda - Recommendation API
resource "aws_iam_role" "lambda_recommendation_role" {
  name = "${var.project_name}-lambda-recommendation-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# Basic Lambda execution role policy
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_recommendation_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# IAM Policy for Lambda - Personalize access
resource "aws_iam_role_policy" "lambda_personalize_policy" {
  name   = "${var.project_name}-lambda-personalize-policy"
  role   = aws_iam_role.lambda_recommendation_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "personalize-runtime:GetRecommendations",
          "personalize-runtime:GetPersonalizedRanking"
        ]
        Resource = "*"
      }
    ]
  })
}

# IAM Role for Lambda - Event Stream
resource "aws_iam_role" "lambda_event_stream_role" {
  name = "${var.project_name}-lambda-event-stream-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# Basic Lambda execution role policy for event stream
resource "aws_iam_role_policy_attachment" "lambda_event_stream_basic_execution" {
  role       = aws_iam_role.lambda_event_stream_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# IAM Policy for Lambda - Kinesis and Personalize Events
resource "aws_iam_role_policy" "lambda_event_stream_policy" {
  name   = "${var.project_name}-lambda-event-stream-policy"
  role   = aws_iam_role.lambda_event_stream_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kinesis:GetRecords",
          "kinesis:GetShardIterator",
          "kinesis:DescribeStream",
          "kinesis:ListStreams",
          "kinesis:ListShards",
          "kinesis:ListStreamConsumers",
          "kinesis:PutRecord",
          "kinesis:PutRecords"
        ]
        Resource = aws_kinesis_stream.user_events.arn
      },
      {
        Effect = "Allow"
        Action = [
          "personalize-events:PutEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

# IAM Role for API Gateway to invoke Lambda
resource "aws_iam_role" "api_gateway_invoke_role" {
  name = "${var.project_name}-api-gateway-invoke-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
      }
    ]
  })
}

# IAM Policy for API Gateway to invoke Lambda
resource "aws_iam_role_policy" "api_gateway_invoke_policy" {
  name   = "${var.project_name}-api-gateway-invoke-policy"
  role   = aws_iam_role.api_gateway_invoke_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction"
        ]
        Resource = [
          aws_lambda_function.recommendation_api.arn,
          "${aws_lambda_function.recommendation_api.arn}:*"
        ]
      }
    ]
  })
}

# IAM Role for API Gateway to invoke Kinesis
resource "aws_iam_role" "api_gateway_kinesis_role" {
  name = "${var.project_name}-api-gateway-kinesis-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
      }
    ]
  })
}

# IAM Policy for API Gateway to put records to Kinesis
resource "aws_iam_role_policy" "api_gateway_kinesis_policy" {
  name   = "${var.project_name}-api-gateway-kinesis-policy"
  role   = aws_iam_role.api_gateway_kinesis_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kinesis:PutRecord",
          "kinesis:PutRecords"
        ]
        Resource = aws_kinesis_stream.user_events.arn
      }
    ]
  })
}
