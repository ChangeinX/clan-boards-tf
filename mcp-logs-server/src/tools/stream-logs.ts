import { CloudWatchService } from '../utils/cloudwatch.js';

export async function streamLogsHandler(cloudWatch: CloudWatchService, args: any) {
  const { service, lines = 50 } = args;

  if (!service) {
    return {
      content: [{
        type: 'text' as const,
        text: 'Error: service parameter is required'
      }],
      isError: true
    };
  }

  try {
    const endTime = new Date();
    const startTime = new Date(endTime.getTime() - (1 * 60 * 60 * 1000)); // Last hour

    const logs = await cloudWatch.fetchLogs(service, {
      startTime,
      endTime,
      limit: lines
    });

    if (logs.length === 0) {
      return {
        content: [{
          type: 'text' as const,
          text: `No recent logs found for service '${service}'`
        }]
      };
    }

    // Sort by timestamp (most recent first for streaming view)
    const sortedLogs = logs.sort((a, b) => 
      new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime()
    );

    const content = [
      `# Recent Logs for ${service}`,
      '',
      `**Last ${lines} entries (most recent first)**`,
      `**Generated:** ${endTime.toISOString()}`,
      '',
      '## Log Stream',
      '',
      ...sortedLogs.map(log => {
        const timestamp = new Date(log.timestamp).toLocaleString();
        const stream = log.logStreamName.split('/').pop() || log.logStreamName; // Get just the stream name part
        return [
          `\`${timestamp}\` **[${stream}]**`,
          '```',
          log.message.trim(),
          '```',
          ''
        ];
      }).flat()
    ].join('\\n');

    return {
      content: [{
        type: 'text' as const,
        text: content
      }]
    };
  } catch (error) {
    return {
      content: [{
        type: 'text' as const,
        text: `Error streaming logs for ${service}: ${error instanceof Error ? error.message : String(error)}`
      }],
      isError: true
    };
  }
}