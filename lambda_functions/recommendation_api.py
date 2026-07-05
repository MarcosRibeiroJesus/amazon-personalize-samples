import json
import boto3
import os
from botocore.exceptions import ClientError

personalize_runtime = boto3.client('personalize-runtime', region_name=os.environ.get('REGION', 'us-east-1'))

CAMPAIGN_ARN = os.environ.get('PERSONALIZE_CAMPAIGN_ARN')

def lambda_handler(event, context):
    """
    Lambda handler for getting recommendations from Amazon Personalize.
    
    Supports both GET and POST requests:
    - GET: /recommendations?userId=123&numResults=10
    - POST: {"userId": "123", "numResults": 10, "filterArn": "optional"}
    """
    
    try:
        # Extract parameters based on request method
        if event.get('httpMethod') == 'GET':
            query_params = event.get('queryStringParameters', {})
            user_id = query_params.get('userId')
            num_results = int(query_params.get('numResults', 10))
        else:  # POST
            body = json.loads(event.get('body', '{}'))
            user_id = body.get('userId')
            num_results = body.get('numResults', 10)
        
        if not user_id:
            return {
                'statusCode': 400,
                'body': json.dumps({'error': 'userId is required'})
            }
        
        # Get recommendations from Personalize
        response = personalize_runtime.get_recommendations(
            campaignArn=CAMPAIGN_ARN,
            userId=str(user_id),
            numResults=num_results
        )
        
        recommendations = [
            {
                'itemId': item['itemId'],
                'score': item['score']
            }
            for item in response.get('itemList', [])
        ]
        
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'userId': user_id,
                'recommendations': recommendations,
                'count': len(recommendations)
            })
        }
    
    except ClientError as e:
        print(f"AWS Error: {e}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': f"AWS Error: {str(e)}"})
        }
    except Exception as e:
        print(f"Error: {e}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': f"Internal Error: {str(e)}"})
        }
