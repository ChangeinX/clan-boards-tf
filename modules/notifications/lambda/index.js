const { SQSClient, SendMessageCommand } = require('@aws-sdk/client-sqs');
const sqs = new SQSClient({});

exports.handler = async (event) => {
  const url = process.env.OUTBOX_QUEUE_URL;
  const records = event.Records || [];
  for (const r of records) {
    if (!r.dynamodb || !r.dynamodb.NewImage) continue;
    const img = r.dynamodb.NewImage;
    const userId = img.userId?.S;
    const payload = img.payload?.S;
    if (!userId || !payload) continue;
    const cmd = new SendMessageCommand({
      QueueUrl: url,
      MessageBody: JSON.stringify({ userId, payload })
    });
    await sqs.send(cmd);
  }
};
