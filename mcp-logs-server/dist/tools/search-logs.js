export async function searchLogsHandler(cloudWatch, args) {
    const { query, services, hours = 1, limit = 100 } = args;
    if (!query) {
        return {
            content: [{
                    type: 'text',
                    text: 'Error: query parameter is required'
                }],
            isError: true
        };
    }
    try {
        const endTime = new Date();
        const startTime = new Date(endTime.getTime() - (hours * 60 * 60 * 1000));
        const logs = await cloudWatch.searchLogs(query, services, {
            startTime,
            endTime,
            limit
        });
        if (logs.length === 0) {
            const serviceList = services ? services.join(', ') : 'all services';
            return {
                content: [{
                        type: 'text',
                        text: `No logs matching query '${query}' found in ${serviceList} for the last ${hours} hour(s)`
                    }]
            };
        }
        // Group logs by service (extracted from log stream name)
        const logsByService = new Map();
        logs.forEach(log => {
            // Extract service name from log stream (assuming format contains service name)
            const serviceMatch = log.logStreamName.match(/(user|messages|notifications|recruiting|clan-data)/);
            const serviceName = serviceMatch ? serviceMatch[1] : 'unknown';
            if (!logsByService.has(serviceName)) {
                logsByService.set(serviceName, []);
            }
            logsByService.get(serviceName).push(log);
        });
        const content = [
            `# Search Results for "${query}"`,
            '',
            `**Time Range:** ${startTime.toISOString()} to ${endTime.toISOString()}`,
            `**Services:** ${services ? services.join(', ') : 'all'}`,
            `**Total Results:** ${logs.length} entries`,
            '',
            ...Array.from(logsByService.entries()).map(([service, serviceLogs]) => [
                `## ${service} (${serviceLogs.length} entries)`,
                '',
                ...serviceLogs.slice(0, 20).map(log => [
                    `**${log.timestamp}** [${log.logStreamName}]`,
                    '```',
                    log.message,
                    '```',
                    ''
                ]).flat(),
                serviceLogs.length > 20 ? `*... ${serviceLogs.length - 20} more entries truncated for brevity*` : '',
                ''
            ]).flat()
        ].filter(Boolean).join('\\n');
        return {
            content: [{
                    type: 'text',
                    text: content
                }]
        };
    }
    catch (error) {
        return {
            content: [{
                    type: 'text',
                    text: `Error searching logs: ${error instanceof Error ? error.message : String(error)}`
                }],
            isError: true
        };
    }
}
//# sourceMappingURL=search-logs.js.map