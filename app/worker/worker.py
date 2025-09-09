import os, json, time, boto3
REGION=os.getenv('AWS_REGION','eu-west-2')
TABLE=os.getenv('DDB_TABLE','emoji_ratings')
QUEUE=os.getenv('SQS_QUEUE_URL')

sqs = boto3.client('sqs', region_name=REGION)
ddb = boto3.client('dynamodb', region_name=REGION)

while True:
    resp = sqs.receive_message(QueueUrl=QUEUE, MaxNumberOfMessages=10, WaitTimeSeconds=10)
    for m in resp.get('Messages', []):
        try:
            item = json.loads(m['Body'])['item']
            ddb.update_item(
              TableName=TABLE,
              Key={'item': {'S': item}},
              UpdateExpression="ADD #c :n",
              ExpressionAttributeNames={'#c':'count'},
              ExpressionAttributeValues={':n': {'N':'1'}}
            )
        finally:
            sqs.delete_message(QueueUrl=QUEUE, ReceiptHandle=m['ReceiptHandle'])
    time.sleep(1)
