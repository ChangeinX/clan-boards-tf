import { CloudWatchService } from '../utils/cloudwatch.js';
export declare function searchLogsHandler(cloudWatch: CloudWatchService, args: any): Promise<{
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
//# sourceMappingURL=search-logs.d.ts.map