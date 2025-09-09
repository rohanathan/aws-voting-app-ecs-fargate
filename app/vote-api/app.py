import os, json, boto3
from flask import Flask, request
app = Flask(__name__)
sqs = boto3.client('sqs', region_name=os.getenv('AWS_REGION','eu-west-2'))
QUEUE_URL = os.getenv('SQS_QUEUE_URL')

@app.route('/health')
def health(): return "OK"
@app.get('/api/vote/health')
def api_health(): return "OK"

@app.post('/api/vote')
def vote():
    data = request.get_json(force=True)
    item = data.get('item')
    if not item: return {"error":"item required"}, 400
    sqs.send_message(QueueUrl=QUEUE_URL, MessageBody=json.dumps({"item":item}))
    return {"status":"queued"}, 202

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)
