const AWS = require('aws-sdk');
const sqs = new AWS.SQS();
const { unmarshall } = AWS.DynamoDB.Converter;

exports.handler = async (event) => {
  for (const record of event.Records) {
    if (record.eventName !== 'INSERT') continue;
    const item = unmarshall(record.dynamodb.NewImage);
    const body = JSON.stringify({ userId: item.userId, payload: item.payload });
    await sqs.sendMessage({ QueueUrl: process.env.QUEUE_URL, MessageBody: body }).promise();
  }
  return {};
};
