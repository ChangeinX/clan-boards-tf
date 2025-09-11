import { LogEntry, LogSearchOptions, ServiceInfo } from '../types.js';
export declare class CloudWatchService {
    private client;
    private services;
    constructor(region?: string);
    getServices(): Promise<ServiceInfo[]>;
    fetchLogs(service: string, options?: LogSearchOptions): Promise<LogEntry[]>;
    searchLogs(query: string, services?: string[], options?: LogSearchOptions): Promise<LogEntry[]>;
    runInsightsQuery(query: string, startTime: Date, endTime: Date): Promise<any[]>;
    getServiceInfo(serviceName: string): ServiceInfo | undefined;
    getAllServices(): ServiceInfo[];
}
//# sourceMappingURL=cloudwatch.d.ts.map