# Magic Movie Machine - Complete Infrastructure Setup Guide

## 🏗️ Architecture Overview

This Terraform configuration creates a complete serverless infrastructure for the Magic Movie Machine recommender system using AWS services:

```
┌─────────────────────────────────────────────────────────────────┐
│                        WEB APPLICATION                          │
│                    (React/Vue/Angular App)                      │
└────────────┬─────────────────────────────────────────────────────┘
             │
             ├─────────────────────────────┬──────────────────────┐
             │                             │                      │
      [GET /recommendations]        [POST /events]          [SDK Integration]
             │                             │                      │
             ▼                             ▼                      ▼
┌──────────────────────────────┐ ┌──────────────────┐  ┌─────────────────┐
│   API GATEWAY REST API       │ │   API GATEWAY    │  │  Event SDK      │
│  - /recommendations (GET)    │ │   → Kinesis      │  │  Client Library │
│  - /recommendations (POST)   │ │     Integration  │  │                 │
└────────────┬─────────────────┘ └─────────┬────────┘  └────────┬────────┘
             │                             │                    │
             │                    ┌────────▼─────────┐          │
             │                    │  KINESIS STREAM  │◄─────────┘
             │                    │  (User Events)   │
             │                    └────────┬─────────┘
             │                             │
             │                    ┌────────▼─────────────────┐
             │                    │  LAMBDA - Event Stream   │
             │                    │  (Event Processing)      │
             │                    └────────┬─────────────────┘
             │                             │
             ▼                             ▼
    ┌─────────────────────┐      ┌──────────────────────────┐
    │  LAMBDA - Rec API   │      │ PERSONALIZE - Events API │
    │  (GetRecommendations│      │ (PutEvents)              │
    │   GetPersonalizedRank)      │                          │
    └────────┬────────────┘      └──────────┬───────────────┘
             │                              │
             ▼                              ▼
    ┌──────────────────────────────────────────┐
    │    AMAZON PERSONALIZE                    │
    │  - Dataset Group (VIDEO_ON_DEMAND)       │
    │  - Datasets (Interactions/Items/Users)   │
    │  - Recommender Model                     │
    │  - Campaigns                             │
    └────────┬─────────────────────────────────┘
             │
             ▼
    ┌──────────────────────┐
    │   S3 BUCKET          │
    │   Training Data      │
    │  - interactions.csv  │
    │  - items.csv         │
    │  - users.csv         │
    └──────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│              MONITORING & LOGGING (CloudWatch)                  │
│  - API Gateway Logs                                             │
│  - Lambda Function Logs                                         │
│  - Alarms & Metrics                                             │
└─────────────────────────────────────────────────────────────────┘
```

## 📋 Prerequisites

- AWS Account with appropriate permissions
- Terraform >= 1.0
- AWS CLI configured with credentials
- Python 3.11 (for Lambda functions)
- MovieLens dataset (or your own training data)

## 🚀 Quick Start

### 1. Initialize Terraform

```bash
cd terraform/
terraform init
```

### 2. Plan the deployment

```bash
terraform plan -out=tfplan
```

### 3. Apply the configuration

```bash
terraform apply tfplan
```

This will create:
- ✅ S3 bucket for training data
- ✅ Kinesis stream for event ingestion
- ✅ Lambda functions (Recommendation API & Event Stream)
- ✅ API Gateway endpoints
- ✅ IAM roles and policies
- ✅ CloudWatch log groups and alarms

### 4. Save the outputs

The Terraform output will provide:
- S3 bucket name
- Kinesis stream ARN
- API Gateway endpoints
- Lambda function names
- Setup instructions

## 📊 Data Setup

### Step 1: Prepare Your Data

The notebook creates three CSV files:

**interactions.csv:**
```
USER_ID,ITEM_ID,TIMESTAMP,EVENT_TYPE
1,1,964982703,watch
1,3,964981247,watch
```

**items.csv:**
```
ITEM_ID,GENRES,YEAR,CREATION_TIMESTAMP
1,Adventure|Animation|Children's|Comedy|Fantasy,1995,1640995200
```

**users.csv:**
```
USER_ID,GENDER
1,male
2,female
```

### Step 2: Upload to S3

After running the notebook, upload the CSV files to the S3 bucket:

```bash
# Get bucket name from Terraform output
BUCKET_NAME=$(terraform output -raw s3_bucket_name)

# Upload files
aws s3 cp interactions.csv s3://$BUCKET_NAME/interactions/
aws s3 cp items.csv s3://$BUCKET_NAME/items/
aws s3 cp users.csv s3://$BUCKET_NAME/users/
```

### Step 3: Create Personalize Resources

Use the AWS Console or Jupyter notebook to:

1. **Create Dataset Group**
   - Name: `personalize-video-on-demand-ds-group`
   - Domain: `VIDEO_ON_DEMAND`

2. **Create Schemas** for each data type:
   - Interactions Schema
   - Items Schema
   - Users Schema

3. **Import Datasets**
   - Link each schema to its S3 CSV file

4. **Create Recommender**
   - Train the model
   - Note the Campaign ARN

### Step 4: Update Lambda Environment Variables

```bash
# Get Lambda function names
REC_LAMBDA=$(terraform output -raw recommendation_lambda_name)
EVENT_LAMBDA=$(terraform output -raw event_stream_lambda_name)

# Update Recommendation API Lambda
aws lambda update-function-configuration \
  --function-name $REC_LAMBDA \
  --environment Variables={PERSONALIZE_CAMPAIGN_ARN=arn:aws:personalize:REGION:ACCOUNT:campaign/YOUR_CAMPAIGN}

# Update Event Stream Lambda
aws lambda update-function-configuration \
  --function-name $EVENT_LAMBDA \
  --environment Variables={DATASET_GROUP_ARN=arn:aws:personalize:REGION:ACCOUNT:dataset-group/YOUR_DATASET_GROUP,TRACKING_ID=YOUR_TRACKING_ID}
```

## 🔌 API Integration

### Get Recommendations

```bash
# GET request
curl "https://API_ENDPOINT/recommendations?userId=1&numResults=10"

# POST request
curl -X POST https://API_ENDPOINT/recommendations \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "1",
    "numResults": 10
  }'
```

**Response:**
```json
{
  "userId": "1",
  "recommendations": [
    {"itemId": "1", "score": 0.95},
    {"itemId": "2", "score": 0.87}
  ],
  "count": 2
}
```

### Send User Events

```bash
curl -X POST https://API_ENDPOINT/events \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "123",
    "itemId": "456",
    "eventType": "watch",
    "timestamp": 1234567890,
    "properties": {"rating": "5"}
  }'
```

**Response:**
```json
{"message": "Event received"}
```

## 💻 Web App Integration

### JavaScript Example

```html
<!DOCTYPE html>
<html>
<head>
  <title>Magic Movie Machine</title>
</head>
<body>
  <div id="recommendations"></div>

  <script>
    // Configuration
    const API_ENDPOINT = 'https://YOUR_API_ENDPOINT';
    const USER_ID = 'user123';

    // Initialize
    async function init() {
      // Get recommendations on load
      await getRecommendations();
      
      // Track user interactions
      trackMovieWatch('movie456', 5);
    }

    // Get Recommendations
    async function getRecommendations() {
      try {
        const response = await fetch(
          `${API_ENDPOINT}/recommendations?userId=${USER_ID}&numResults=10`
        );
        const data = await response.json();
        
        displayRecommendations(data.recommendations);
      } catch (error) {
        console.error('Error fetching recommendations:', error);
      }
    }

    // Track User Events
    async function trackMovieWatch(movieId, rating) {
      try {
        await fetch(`${API_ENDPOINT}/events`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            userId: USER_ID,
            itemId: movieId,
            eventType: 'watch',
            timestamp: Math.floor(Date.now() / 1000),
            properties: { rating: rating }
          })
        });
        console.log('Event tracked successfully');
      } catch (error) {
        console.error('Error tracking event:', error);
      }
    }

    // Display recommendations
    function displayRecommendations(recommendations) {
      const container = document.getElementById('recommendations');
      container.innerHTML = recommendations
        .map(rec => `
          <div class="movie-card">
            <h3>Movie ${rec.itemId}</h3>
            <p>Confidence: ${(rec.score * 100).toFixed(2)}%</p>
            <button onclick="trackMovieWatch('${rec.itemId}', 5)">Watch</button>
          </div>
        `)
        .join('');
    }

    // Start on page load
    init();
  </script>
</body>
</html>
```

## 🔍 Monitoring

### CloudWatch Metrics

Monitor your infrastructure:

```bash
# View Lambda logs
aws logs tail /aws/lambda/magic-movie-machine-recommendation-api-dev --follow

# View API Gateway logs
aws logs tail /aws/apigateway/magic-movie-machine-dev --follow

# Check Kinesis metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/Kinesis \
  --metric-name GetRecords.IteratorAgeMilliseconds \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-01-02T00:00:00Z \
  --period 300 \
  --statistics Maximum
```

### CloudWatch Alarms

Alarms are automatically created for:
- Lambda function errors
- Kinesis stream issues
- Iterator age monitoring

## 🧹 Cleanup

To remove all resources:

```bash
cd terraform/
terraform destroy
```

**Warning:** This will delete:
- S3 bucket (if not empty, manually delete objects first)
- Kinesis stream
- Lambda functions
- API Gateway
- IAM roles
- CloudWatch resources

## 📁 Project Structure

```
.
├── terraform/
│   ├── provider.tf           # AWS provider configuration
│   ├── variables.tf          # Input variables
│   ├── iam.tf                # IAM roles and policies
│   ├── s3.tf                 # S3 bucket configuration
│   ├── kinesis.tf            # Kinesis stream configuration
│   ├── lambda.tf             # Lambda functions
│   ├── api_gateway.tf        # API Gateway configuration
│   ├── cloudwatch.tf         # CloudWatch logs and alarms
│   └── outputs.tf            # Terraform outputs
├── lambda_functions/
│   ├── recommendation_api.py  # Recommendation Lambda
│   └── event_stream.py        # Event stream Lambda
├── terraform.tfvars          # Environment-specific variables (create this)
└── README.md                 # This file
```

## ⚙️ Customization

### Change AWS Region

```bash
terraform apply -var="aws_region=eu-west-1"
```

### Adjust Lambda Memory/Timeout

```bash
terraform apply \
  -var="lambda_memory=512" \
  -var="lambda_timeout=120"
```

### Scale Kinesis

```bash
terraform apply -var="kinesis_shard_count=5"
```

## 🆘 Troubleshooting

### Lambda not processing events

1. Check CloudWatch logs:
   ```bash
   aws logs tail /aws/lambda/magic-movie-machine-event-stream-dev --follow
   ```

2. Verify Kinesis stream has data:
   ```bash
   aws kinesis describe-stream \
     --stream-name magic-movie-machine-user-events-dev
   ```

3. Check Lambda environment variables:
   ```bash
   aws lambda get-function-configuration \
     --function-name magic-movie-machine-event-stream-dev
   ```

### API Gateway returning 500 errors

1. Check Lambda logs
2. Verify PERSONALIZE_CAMPAIGN_ARN is set correctly
3. Ensure Personalize campaign is active
4. Test Lambda directly:
   ```bash
   aws lambda invoke \
     --function-name magic-movie-machine-recommendation-api-dev \
     --payload '{"httpMethod":"GET","queryStringParameters":{"userId":"1","numResults":"10"}}' \
     response.json
   ```

### Cross-Origin Issues

API Gateway CORS is automatically enabled. If issues persist:

```bash
# Add CORS headers manually
aws apigateway put-integration-response \
  --rest-api-id API_ID \
  --resource-id RESOURCE_ID \
  --http-method GET \
  --status-code 200 \
  --response-parameters 'method.response.header.Access-Control-Allow-Origin'='"*"'
```

## 📚 Additional Resources

- [AWS Personalize Documentation](https://docs.aws.amazon.com/personalize/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Magic Movie Machine Workshop](https://github.com/aws-samples/amazon-personalize-samples)
- [API Gateway Best Practices](https://docs.aws.amazon.com/apigateway/latest/developerguide/)
- [AWS Lambda Best Practices](https://docs.aws.amazon.com/lambda/latest/dg/best-practices.html)

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.
