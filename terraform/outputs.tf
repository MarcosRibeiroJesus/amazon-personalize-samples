output "s3_bucket_name" {
  description = "Name of the S3 bucket for Personalize data"
  value       = aws_s3_bucket.personalize_data.id
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket for Personalize data"
  value       = aws_s3_bucket.personalize_data.arn
}

output "kinesis_stream_name" {
  description = "Name of the Kinesis stream for user events"
  value       = aws_kinesis_stream.user_events.name
}

output "kinesis_stream_arn" {
  description = "ARN of the Kinesis stream"
  value       = aws_kinesis_stream.user_events.arn
}

output "api_gateway_endpoint" {
  description = "API Gateway endpoint URL"
  value       = aws_api_gateway_stage.recommendation_api.invoke_url
}

output "api_gateway_invoke_url" {
  description = "Full API Gateway invoke URL for recommendations"
  value       = "${aws_api_gateway_stage.recommendation_api.invoke_url}/recommendations"
}

output "api_gateway_events_url" {
  description = "Full API Gateway invoke URL for events ingestion"
  value       = "${aws_api_gateway_stage.recommendation_api.invoke_url}/events"
}

output "recommendation_lambda_name" {
  description = "Name of the Recommendation API Lambda function"
  value       = aws_lambda_function.recommendation_api.function_name
}

output "event_stream_lambda_name" {
  description = "Name of the Event Stream Lambda function"
  value       = aws_lambda_function.event_stream.function_name
}

output "personalize_role_arn" {
  description = "ARN of the Personalize IAM role"
  value       = aws_iam_role.personalize_role.arn
}

output "lambda_recommendation_role_arn" {
  description = "ARN of the Lambda Recommendation API IAM role"
  value       = aws_iam_role.lambda_recommendation_role.arn
}

output "lambda_event_stream_role_arn" {
  description = "ARN of the Lambda Event Stream IAM role"
  value       = aws_iam_role.lambda_event_stream_role.arn
}

output "setup_instructions" {
  description = "Next steps to set up the infrastructure"
  value       = <<-EOT

╔══════════════════════════════════════════════════════════════════════════╗
║     Magic Movie Machine - Infrastructure Deployment Complete ✓           ║
╚══════════════════════════════════════════════════════════════════════════╝

✓ S3 Bucket created: ${aws_s3_bucket.personalize_data.id}
✓ Kinesis Stream created: ${aws_kinesis_stream.user_events.name}
✓ Lambda Functions deployed
✓ API Gateway configured

═══════════════════════════════════════════════════════════════════════════
NEXT STEPS:
═══════════════════════════════════════════════════════════════════════════

1. Upload training data to S3:
   ▶ interactions.csv → s3://${aws_s3_bucket.personalize_data.id}/interactions/
   ▶ items.csv → s3://${aws_s3_bucket.personalize_data.id}/items/
   ▶ users.csv → s3://${aws_s3_bucket.personalize_data.id}/users/

2. Create Personalize resources using AWS Console:
   ▶ Dataset Group: ${var.dataset_group_name}
   ▶ Create Schemas (Interactions, Items, Users)
   ▶ Import datasets from S3
   ▶ Train recommender model
   ▶ Note the Campaign ARN

3. Update Lambda environment variables:
   ▶ ${aws_lambda_function.recommendation_api.function_name}
     Set: PERSONALIZE_CAMPAIGN_ARN = <your-campaign-arn>
   
   ▶ ${aws_lambda_function.event_stream.function_name}
     Set: DATASET_GROUP_ARN = <your-dataset-group-arn>

4. Test the API endpoints:
   
   GET Recommendations:
   curl "${aws_api_gateway_stage.recommendation_api.invoke_url}/recommendations?userId=1&numResults=10"
   
   POST Events:
   curl -X POST ${aws_api_gateway_stage.recommendation_api.invoke_url}/events \
     -H "Content-Type: application/json" \
     -d '{"userId": "1", "itemId": "1", "eventType": "watch", "timestamp": 1234567890}'

5. Integrate with web app using Event Ingestion SDK:
   Event Stream URL: ${aws_api_gateway_stage.recommendation_api.invoke_url}/events
   
   Example JavaScript integration:
   fetch('${aws_api_gateway_stage.recommendation_api.invoke_url}/events', {
     method: 'POST',
     headers: { 'Content-Type': 'application/json' },
     body: JSON.stringify({
       userId: userID,
       itemId: movieID,
       eventType: 'watch',
       timestamp: Math.floor(Date.now() / 1000)
     })
   })

═══════════════════════════════════════════════════════════════════════════
RESOURCES:
═══════════════════════════════════════════════════════════════════════════

S3 Bucket ARN:              ${aws_s3_bucket.personalize_data.arn}
Kinesis Stream ARN:         ${aws_kinesis_stream.user_events.arn}
Lambda Recommendation ARN:  ${aws_lambda_function.recommendation_api.arn}
Lambda Event Stream ARN:    ${aws_lambda_function.event_stream.arn}

═══════════════════════════════════════════════════════════════════════════
  EOT
}
