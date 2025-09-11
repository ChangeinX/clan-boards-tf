import { LogEntry, ErrorPattern, LogAnalysis } from '../types.js';

export class LogParser {
  private static ERROR_PATTERNS = [
    { pattern: /ERROR|Error|error/g, severity: 'HIGH' as const },
    { pattern: /FATAL|Fatal|fatal/g, severity: 'CRITICAL' as const },
    { pattern: /WARN|Warning|warning/g, severity: 'MEDIUM' as const },
    { pattern: /Exception|exception/g, severity: 'HIGH' as const },
    { pattern: /failed|Failed|FAILED/g, severity: 'MEDIUM' as const },
    { pattern: /timeout|Timeout|TIMEOUT/g, severity: 'MEDIUM' as const },
    { pattern: /500|502|503|504/g, severity: 'HIGH' as const },
    { pattern: /unauthorized|Unauthorized|403/g, severity: 'MEDIUM' as const },
    { pattern: /not found|Not Found|404/g, severity: 'LOW' as const }
  ];

  static analyzeErrors(logs: LogEntry[]): ErrorPattern[] {
    const errorCounts = new Map<string, {
      count: number;
      firstSeen: string;
      lastSeen: string;
      severity: 'LOW' | 'MEDIUM' | 'HIGH' | 'CRITICAL';
    }>();

    for (const log of logs) {
      for (const { pattern, severity } of this.ERROR_PATTERNS) {
        const matches = log.message.match(pattern);
        if (matches) {
          const key = `${pattern.source}_${severity}`;
          const existing = errorCounts.get(key);
          
          if (existing) {
            existing.count += matches.length;
            existing.lastSeen = log.timestamp;
          } else {
            errorCounts.set(key, {
              count: matches.length,
              firstSeen: log.timestamp,
              lastSeen: log.timestamp,
              severity
            });
          }
        }
      }
    }

    return Array.from(errorCounts.entries()).map(([key, data]) => ({
      pattern: key.split('_')[0],
      count: data.count,
      firstSeen: data.firstSeen,
      lastSeen: data.lastSeen,
      severity: data.severity
    })).sort((a, b) => b.count - a.count);
  }

  static extractRequestId(message: string): string | null {
    const patterns = [
      /request[_-]?id[:\s=]+([a-f0-9-]+)/i,
      /trace[_-]?id[:\s=]+([a-f0-9-]+)/i,
      /correlation[_-]?id[:\s=]+([a-f0-9-]+)/i,
      /x-request-id[:\s=]+([a-f0-9-]+)/i
    ];

    for (const pattern of patterns) {
      const match = message.match(pattern);
      if (match) {
        return match[1];
      }
    }
    return null;
  }

  static extractHttpStatus(message: string): number | null {
    const match = message.match(/\\b(200|201|204|300|301|302|304|400|401|403|404|405|422|429|500|502|503|504)\\b/);
    return match ? parseInt(match[1], 10) : null;
  }

  static extractDuration(message: string): number | null {
    const patterns = [
      /duration[:\s=]+(\\d+(?:\\.\\d+)?)\\s*ms/i,
      /took\\s+(\\d+(?:\\.\\d+)?)\\s*ms/i,
      /in\\s+(\\d+(?:\\.\\d+)?)\\s*ms/i,
      /(\\d+(?:\\.\\d+)?)ms/i
    ];

    for (const pattern of patterns) {
      const match = message.match(pattern);
      if (match) {
        return parseFloat(match[1]);
      }
    }
    return null;
  }

  static analyzePerformance(logs: LogEntry[]): {
    averageDuration: number | null;
    slowRequests: LogEntry[];
    httpStatusCodes: Record<number, number>;
  } {
    const durations: number[] = [];
    const slowRequests: LogEntry[] = [];
    const httpStatusCodes: Record<number, number> = {};

    for (const log of logs) {
      const duration = this.extractDuration(log.message);
      if (duration !== null) {
        durations.push(duration);
        if (duration > 1000) { // Consider requests over 1 second as slow
          slowRequests.push(log);
        }
      }

      const status = this.extractHttpStatus(log.message);
      if (status !== null) {
        httpStatusCodes[status] = (httpStatusCodes[status] || 0) + 1;
      }
    }

    const averageDuration = durations.length > 0 
      ? durations.reduce((a, b) => a + b, 0) / durations.length 
      : null;

    return {
      averageDuration,
      slowRequests: slowRequests.sort((a, b) => new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime()),
      httpStatusCodes
    };
  }

  static analyzeLogs(logs: LogEntry[]): LogAnalysis {
    if (logs.length === 0) {
      return {
        totalEntries: 0,
        timeRange: { start: '', end: '' },
        errorPatterns: [],
        topLogStreams: []
      };
    }

    const sortedLogs = logs.sort((a, b) => new Date(a.timestamp).getTime() - new Date(b.timestamp).getTime());
    
    const streamCounts = new Map<string, number>();
    for (const log of logs) {
      streamCounts.set(log.logStreamName, (streamCounts.get(log.logStreamName) || 0) + 1);
    }

    const topLogStreams = Array.from(streamCounts.entries())
      .sort((a, b) => b[1] - a[1])
      .slice(0, 10)
      .map(([streamName, count]) => ({ streamName, count }));

    return {
      totalEntries: logs.length,
      timeRange: {
        start: sortedLogs[0].timestamp,
        end: sortedLogs[sortedLogs.length - 1].timestamp
      },
      errorPatterns: this.analyzeErrors(logs),
      topLogStreams
    };
  }

  static filterByTimeRange(logs: LogEntry[], startTime?: Date, endTime?: Date): LogEntry[] {
    return logs.filter(log => {
      const logTime = new Date(log.timestamp).getTime();
      if (startTime && logTime < startTime.getTime()) return false;
      if (endTime && logTime > endTime.getTime()) return false;
      return true;
    });
  }

  static searchInMessages(logs: LogEntry[], searchTerm: string, caseSensitive: boolean = false): LogEntry[] {
    const term = caseSensitive ? searchTerm : searchTerm.toLowerCase();
    return logs.filter(log => {
      const message = caseSensitive ? log.message : log.message.toLowerCase();
      return message.includes(term);
    });
  }
}