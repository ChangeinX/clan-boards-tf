import { CloudWatchService } from '../utils/cloudwatch.js';
export declare function analyzeErrorsHandler(cloudWatch: CloudWatchService, args: any): Promise<{
    content: {
        type: "text";
        text: string;
    }[];
    isError?: undefined;
} | {
    content: {
        type: "text";
        text: string;
    }[];
    isError: boolean;
}>;
//# sourceMappingURL=analyze-errors.d.ts.map