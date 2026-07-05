import json
import boto3
import base64
import os
from datetime import datetime
from botocore.exceptions import ClientError

personalize_events = boto3.client('personalize-events', region_name=os.environ.get('REGION', 'us-east-1'))

DATASET_GROUP_ARN = os.environ.get('DATASET_GROUP_ARN')
REGION = os.environ.get('REGION', 'us-east-1')
TRACKING_ID = os.environ.get('TRACKING_ID', '')

def lambda_handler(event, context):
    """
    Lambda handler for processing user interaction events from Kinesis stream.
    
    Receives events from Kinesis and sends them to Personalize Events API.
    Expected event format:
    {
        "userId": "123",
        "itemId": "456",
        "eventType": "watch",
        "timestamp": 1234567890,
        "properties": {"rating": "5"} (optional)
    }
    """
    
    print(f"Processing {len(event.get('Records', []))} records")
    
    try:
        # Process Kinesis records
        for record in event.get('Records', []):
            try:
                # Decode Kinesis data
                payload = base64.b64decode(record['kinesis']['data']).decode('utf-8')
                event_data = json.loads(payload)
                
                print(f"Processing event: {event_data}")
                
                # Validate required fields
                required_fields = ['userId', 'itemId', 'eventType']
                if not all(field in event_data for field in required_fields):
                    print(f"Skipping event - missing required fields: {event_data}")
                    continue
                
                # Add timestamp if not provided
                if 'timestamp' not in event_data:
                    event_data['timestamp'] = int(datetime.now().timestamp())
                
                # Prepare event for Personalize
                personalize_event = {
                    'userId': str(event_data['userId']),
                    'itemId': str(event_data['itemId']),
                    'eventType': event_data['eventType'],
                    'sentAt': int(event_data['timestamp'])
                }
                
                # Add optional properties
                event_properties = event_data.get('properties', {})
                
                try:
                    # Send event to Personalize
                    response = personalize_events.put_events(
                        trackingId=TRACKING_ID if TRACKING_ID else DATASET_GROUP_ARN,
                        userId=personalize_event['userId'],
                        sessionId=event_data.get('sessionId', personalize_event['userId']),
                        eventList=[
                            {
                                'sentAt': personalize_event['sentAt'],
                                'eventType': personalize_event['eventType'],
                                'itemId': personalize_event['itemId'],
                                'properties': json.dumps(event_properties) if event_properties else '{}'
                            }
                        ]
                    )
                    
                    print(f"Event sent to Personalize successfully")
                
                except ClientError as e:
                    error_code = e.response['Error']['Code']
                    print(f"Error sending event to Personalize [{error_code}]: {e}")
                    # Continue processing other events even if one fails
                    continue
            
            except json.JSONDecodeError as e:
                print(f"Error decoding JSON from Kinesis record: {e}")
                continue
            except Exception as e:
                print(f"Error processing individual record: {e}")
                continue
        
        return {
            'statusCode': 200,
            'body': json.dumps({'message': 'Events processed successfully'})
        }
    
    except Exception as e:
        print(f"Error processing events: {e}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': f"Error: {str(e)}"})
        }
