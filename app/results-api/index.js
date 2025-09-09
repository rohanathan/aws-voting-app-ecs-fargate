const express = require('express');
const AWS = require('aws-sdk');
const app = express();
const PORT = process.env.PORT || 8080;
const REGION = process.env.AWS_REGION || 'eu-west-2';
const TABLE  = process.env.DDB_TABLE || 'emoji_ratings';
AWS.config.update({region: REGION});
const ddb = new AWS.DynamoDB();

app.get('/health', (_,res)=>res.send('OK'));
app.get('/api/results/health', (_,res)=>res.send('OK'));
app.get('/api/results', async (_,res)=>{
  const params = {
    TableName: TABLE,
    ProjectionExpression: "#i, #c",
    ExpressionAttributeNames: {"#i":"item", "#c":"count"},
    ConsistentRead: true
  };
  const data = await ddb.scan(params).promise();
  const out = Object.fromEntries((data.Items||[]).map(x=>[x.item.S, Number(x.count.N)]));
  res.json(out);
});

app.listen(PORT, ()=>console.log('results on', PORT));
