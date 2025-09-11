import { CloudWatchService } from '../utils/cloudwatch.js';

export async function fetchLogsHandler(cloudWatch: CloudWatchService, args: any) {
  const { service, hours = 1, limit = 100, filter } = args;

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
    const startTime = new Date(endTime.getTime() - (hours * 60 * 60 * 1000));

    const logs = await cloudWatch.fetchLogs(service, {
      startTime,
      endTime,
      filterPattern: filter,
      limit
    });

    if (logs.length === 0) {
      return {
        content: [{
          type: 'text' as const,
          text: `No logs found for service '${service}' in the last ${hours} hour(s)`
        }]
      };
    }

    const content = [
      `# Logs for ${service}`,
      ``,
      `**Time Range:** ${startTime.toISOString()} to ${endTime.toISOString()}`,
      `**Filter:** ${filter || 'None'}`,
      `**Count:** ${logs.length} entries`,
      ``,
      '## Log Entries',
      '',
      ...logs.map(log => [
        `**${log.timestamp}** [${log.logStreamName}]`,
        '```',
        log.message,
        '```',
        ''
      ]).flat()
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
        text: `Error fetching logs for ${service}: ${error instanceof Error ? error.message : String(error)}`
      }],
      isError: true
    };
  }
}