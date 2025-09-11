import { LogEntry, ErrorPattern, LogAnalysis } from '../types.js';
export declare class LogParser {
    private static ERROR_PATTERNS;
    static analyzeErrors(logs: LogEntry[]): ErrorPattern[];
    static extractRequestId(message: string): string | null;
    static extractHttpStatus(message: string): number | null;
    static extractDuration(message: string): number | null;
    static analyzePerformance(logs: LogEntry[]): {
        averageDuration: number | null;
        slowRequests: LogEntry[];
        httpStatusCodes: Record<number, number>;
    };
    static analyzeLogs(logs: LogEntry[]): LogAnalysis;
    static filterByTimeRange(logs: LogEntry[], startTime?: Date, endTime?: Date): LogEntry[];
    static searchInMessages(logs: LogEntry[], searchTerm: string, caseSensitive?: boolean): LogEntry[];
}
//# sourceMappingURL=log-parser.d.ts.map