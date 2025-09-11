export interface LogEntry {
    timestamp: string;
    message: string;
    logStreamName: string;
    ingestionTime: number;
}
export interface ServiceInfo {
    name: string;
    logGroup: string;
    port?: number;
    description?: string;
}
export interface LogSearchOptions {
    startTime?: Date;
    endTime?: Date;
    filterPattern?: string;
    limit?: number;
    nextToken?: string;
}
export interface ErrorPattern {
    pattern: string;
    count: number;
    firstSeen: string;
    lastSeen: string;
    severity: 'LOW' | 'MEDIUM' | 'HIGH' | 'CRITICAL';
}
export interface LogAnalysis {
    totalEntries: number;
    timeRange: {
        start: string;
        end: string;
    };
    errorPatterns: ErrorPattern[];
    topLogStreams: Array<{
        streamName: string;
        count: number;
    }>;
}
export interface StreamLogOptions {
    service: string;
    tailLines?: number;
    follow?: boolean;
}
//# sourceMappingURL=types.d.ts.map