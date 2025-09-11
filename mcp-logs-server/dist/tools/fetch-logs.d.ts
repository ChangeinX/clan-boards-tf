import { CloudWatchService } from '../utils/cloudwatch.js';
export declare function fetchLogsHandler(cloudWatch: CloudWatchService, args: any): Promise<{
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
//# sourceMappingURL=fetch-logs.d.ts.map