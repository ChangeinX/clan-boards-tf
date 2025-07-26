const { SQSClient, SendMessageCommand } = require('@aws-sdk/client-sqs');
const { unmarshall } = require('@aws-sdk/util-dynamodb');

const sqs = new SQSClient({});

exports.handler = async (event) => {
  for (const record of event.Records) {
    if (record.eventName !== 'INSERT') continue;
    const item = unmarshall(record.dynamodb.NewImage);
    const body = JSON.stringify({ userId: item.userId, payload: item.payload });
    const command = new SendMessageCommand({
      QueueUrl: process.env.QUEUE_URL,
      MessageBody: body,
    });
    await sqs.send(command);  }
  return {};
};
