import { CloudWatchService } from '../utils/cloudwatch.js';
import { LogParser } from '../utils/log-parser.js';

export async function analyzeErrorsHandler(cloudWatch: CloudWatchService, args: any) {
  const { service, hours = 24 } = args;

  try {
    const endTime = new Date();
    const startTime = new Date(endTime.getTime() - (hours * 60 * 60 * 1000));

    let allLogs;
    
    if (service) {
      // Analyze single service
      allLogs = await cloudWatch.fetchLogs(service, {
        startTime,
        endTime,
        limit: 1000 // Increase limit for better analysis
      });
    } else {
      // Analyze all services
      const services = await cloudWatch.getServices();
      allLogs = [];
      
      for (const svc of services) {
        try {
          const logs = await cloudWatch.fetchLogs(svc.name, {
            startTime,
            endTime,
            limit: 500 // Per service limit
          });
          allLogs.push(...logs);
        } catch (error) {
          console.error(`Error fetching logs for ${svc.name}:`, error);
        }
      }
    }

    if (allLogs.length === 0) {
      const target = service || 'all services';
      return {
        content: [{
          type: 'text' as const,
          text: `No logs found for ${target} in the last ${hours} hour(s)`
        }]
      };
    }

    // Perform comprehensive analysis
    const analysis = LogParser.analyzeLogs(allLogs);
    const performanceAnalysis = LogParser.analyzePerformance(allLogs);

    // Group logs by service for service-specific insights
    const logsByService = new Map<string, typeof allLogs>();
    allLogs.forEach(log => {
      const serviceMatch = log.logStreamName.match(/(user|messages|notifications|recruiting|clan-data)/);
      const serviceName = serviceMatch ? serviceMatch[1] : 'unknown';
      
      if (!logsByService.has(serviceName)) {
        logsByService.set(serviceName, []);
      }
      logsByService.get(serviceName)!.push(log);
    });

    const content = [
      `# Log Analysis Report`,
      '',
      `**Analysis Target:** ${service || 'All Services'}`,
      `**Time Range:** ${startTime.toISOString()} to ${endTime.toISOString()}`,
      `**Total Log Entries:** ${analysis.totalEntries}`,
      '',
      '## Error Summary',
      '',
      analysis.errorPatterns.length > 0 ? [
        '| Pattern | Count | Severity | First Seen | Last Seen |',
        '|---------|--------|----------|------------|-----------|',
        ...analysis.errorPatterns.slice(0, 10).map(pattern => 
          `| ${pattern.pattern} | ${pattern.count} | ${pattern.severity} | ${new Date(pattern.firstSeen).toLocaleString()} | ${new Date(pattern.lastSeen).toLocaleString()} |`
        )
      ].join('\\n') : 'No error patterns detected.',
      '',
      '## Performance Insights',
      '',
      performanceAnalysis.averageDuration !== null ? [
        `**Average Response Time:** ${performanceAnalysis.averageDuration.toFixed(2)}ms`,
        `**Slow Requests (>1s):** ${performanceAnalysis.slowRequests.length}`,
        ''
      ].join('\\n') : 'No performance metrics available.',
      '',
      '### HTTP Status Codes',
      Object.keys(performanceAnalysis.httpStatusCodes).length > 0 ? [
        '| Status Code | Count |',
        '|-------------|-------|',
        ...Object.entries(performanceAnalysis.httpStatusCodes)
          .sort((a, b) => b[1] - a[1])
          .map(([status, count]) => `| ${status} | ${count} |`)
      ].join('\\n') : 'No HTTP status codes detected.',
      '',
      '## Top Log Sources',
      '',
      '| Log Stream | Entries |',
      '|------------|---------|',
      ...analysis.topLogStreams.slice(0, 10).map(stream => 
        `| ${stream.streamName} | ${stream.count} |`
      ),
      '',
      service ? '' : [
        '## Service Breakdown',
        '',
        ...Array.from(logsByService.entries()).map(([svc, logs]) => {
          const serviceErrors = LogParser.analyzeErrors(logs);
          const topErrors = serviceErrors.slice(0, 3);
          return [
            `### ${svc} (${logs.length} entries)`,
            topErrors.length > 0 ? [
              'Top errors:',
              ...topErrors.map(e => `- ${e.pattern}: ${e.count} occurrences (${e.severity})`)
            ].join('\\n') : 'No errors detected.',
            ''
          ].join('\\n');
        }),
        ''
      ].join('\\n'),
      performanceAnalysis.slowRequests.length > 0 ? [
        '## Recent Slow Requests',
        '',
        ...performanceAnalysis.slowRequests.slice(0, 5).map(log => [
          `**${log.timestamp}** [${log.logStreamName}]`,
          '```',
          log.message.substring(0, 200) + (log.message.length > 200 ? '...' : ''),
          '```',
          ''
        ]).flat()
      ].join('\\n') : ''
    ].filter(Boolean).join('\\n');

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
        text: `Error analyzing logs: ${error instanceof Error ? error.message : String(error)}`
      }],
      isError: true
    };
  }
}