import { CloudWatchService } from '../utils/cloudwatch.js';

export async function listServicesHandler(cloudWatch: CloudWatchService) {
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
        type: 'text' as const,
        text: content
      }]
    };
  } catch (error) {
    return {
      content: [{
        type: 'text' as const,
        text: `Error listing services: ${error instanceof Error ? error.message : String(error)}`
      }],
      isError: true
    };
  }
}