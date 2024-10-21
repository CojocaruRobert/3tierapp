import json
import boto3
import os

dynamodb = boto3.resource('dynamodb')
table_name = os.environ['DYNAMODB_TABLE']
table = dynamodb.Table(table_name)

def lambda_handler(event, context):
    headers = {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Content-Type',
        'Access-Control-Allow-Methods': 'GET, POST, OPTIONS'
    }
    
    if event['httpMethod'] == 'GET':
        response = table.scan()
        items = response.get('Items', [])
        return {
            'statusCode': 200,
            'headers': headers,
            'body': json.dumps({'data': items})
        }
    
    elif event['httpMethod'] == 'POST':
        body = json.loads(event['body'])
        message = body['message']

        response = table.scan()
        items = response.get('Items', [])
        
        max_id = 0
        if items:
            max_id = max(int(item['id']) for item in items)
        new_id = str(max_id + 1)

        table.put_item(Item={'id': new_id, 'message': message})

        return {
            'statusCode': 200,
            'headers': headers,
            'body': json.dumps({'message': 'Item added successfully', 'id': new_id})
        }
    
    else:
        return {
            'statusCode': 400,
            'headers': headers,
            'body': json.dumps({'message': 'Unsupported method'})
        }