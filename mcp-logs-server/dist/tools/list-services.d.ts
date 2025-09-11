import { CloudWatchService } from '../utils/cloudwatch.js';
export declare function listServicesHandler(cloudWatch: CloudWatchService): Promise<{
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
//# sourceMappingURL=list-services.d.ts.map