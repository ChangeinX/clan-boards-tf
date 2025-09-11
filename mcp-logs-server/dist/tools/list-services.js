export async function listServicesHandler(cloudWatch) {
    try {
        const services = await cloudWatch.getServices();
        const content = [
            '# Available Services',
            '',
            'The following services are available for log analysis:',
            '',
            ...services.map(service => [
                `## ${service.name}`,
                `- **Log Group:** ${service.logGroup}`,
                service.port ? `- **Port:** ${service.port}` : '',
                service.description ? `- **Description:** ${service.description}` : '',
                ''
            ].filter(Boolean)).flat()
        ].join('\\n');
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
                    text: `Error listing services: ${error instanceof Error ? error.message : String(error)}`
                }],
            isError: true
        };
    }
}
//# sourceMappingURL=list-services.js.map