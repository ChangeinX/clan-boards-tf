import { CloudWatchService } from '../utils/cloudwatch.js';
export declare function streamLogsHandler(cloudWatch: CloudWatchService, args: any): Promise<{
    content: {
        type: "text";
        text: string;
    }[];
    isError: boolean;
} | {
    content: {
        type: "text";
        text: string;
    }[];
    isError?: undefined;
}>;
//# sourceMappingURL=stream-logs.d.ts.map