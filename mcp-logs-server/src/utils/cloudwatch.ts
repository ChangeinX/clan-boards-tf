import {
  CloudWatchLogsClient,
  DescribeLogGroupsCommand,
  FilterLogEventsCommand,
  StartQueryCommand,
  GetQueryResultsCommand,
  type FilterLogEventsCommandInput,
  type FilteredLogEvent,
  type QueryStatus
} from '@aws-sdk/client-cloudwatch-logs';
import { LogEntry, LogSearchOptions, ServiceInfo } from '../types.js';

export class CloudWatchService {
  private client: CloudWatchLogsClient;
  private services: ServiceInfo[];

  constructor(region: string = 'us-east-1') {
    this.client = new CloudWatchLogsClient({ region });
    this.services = [
      { name: 'user', logGroup: '/ecs/webapp-user', port: 8020, description: 'User authentication service' },
      { name: 'messages', logGroup: '/ecs/webapp-messages', port: 8010, description: 'Message processing service' },
      { name: 'notifications', logGroup: '/ecs/webapp-notifications', port: 8030, description: 'Push notification service' },
      { name: 'recruiting', logGroup: '/ecs/webapp-recruiting', port: 8040, description: 'Recruiting management service' },
      { name: 'clan-data', logGroup: '/ecs/webapp-clan-data', port: 8050, description: 'Clan data aggregation service' },
      { name: 'coc-giveaway-bot', logGroup: '/ecs/coc-giveaway-bot', description: 'Clash of Clans giveaway bot service' },
      { name: 'coc-verifier-bot', logGroup: '/ecs/coc-verifier-bot', description: 'Clash of Clans verification bot service' }
    ];
  }

  async getServices(): Promise<ServiceInfo[]> {
    try {
      const command = new DescribeLogGroupsCommand({
        logGroupNamePrefix: '/ecs/'
      });
      const response = await this.client.send(command);
      
      // Filter out health check related logs and match with our known services
      const availableGroups = response.logGroups?.map(lg => lg.logGroupName).filter(Boolean) || [];
      
      return this.services.filter(service => 
        availableGroups.includes(service.logGroup)
      );
    } catch (error) {
      console.error('Error fetching services:', error);
      return this.services; // Return default list if API fails
    }
  }

  async fetchLogs(service: string, options: LogSearchOptions = {}): Promise<LogEntry[]> {
    const serviceInfo = this.services.find(s => s.name === service);
    if (!serviceInfo) {
      throw new Error(`Service '${service}' not found`);
    }

    const params: FilterLogEventsCommandInput = {
      logGroupName: serviceInfo.logGroup,
      startTime: options.startTime?.getTime(),
      endTime: options.endTime?.getTime(),
      filterPattern: options.filterPattern,
      limit: options.limit || 100,
      nextToken: options.nextToken
    };

    try {
      const command = new FilterLogEventsCommand(params);
      const response = await this.client.send(command);

      return (response.events || []).map((event: FilteredLogEvent): LogEntry => ({
        timestamp: new Date(event.timestamp || 0).toISOString(),
        message: event.message || '',
        logStreamName: event.logStreamName || '',
        ingestionTime: event.ingestionTime || 0
      }));
    } catch (error) {
      console.error(`Error fetching logs for ${service}:`, error);
      throw error;
    }
  }

  async searchLogs(query: string, services?: string[], options: LogSearchOptions = {}): Promise<LogEntry[]> {
    const servicesToSearch = services?.length 
      ? this.services.filter(s => services.includes(s.name))
      : this.services;

    const results: LogEntry[] = [];
    
    for (const service of servicesToSearch) {
      try {
        const logs = await this.fetchLogs(service.name, {
          ...options,
          filterPattern: query
        });
        results.push(...logs);
      } catch (error) {
        console.error(`Error searching logs for ${service.name}:`, error);
      }
    }

    // Sort by timestamp
    return results.sort((a, b) => new Date(a.timestamp).getTime() - new Date(b.timestamp).getTime());
  }

  async runInsightsQuery(query: string, startTime: Date, endTime: Date): Promise<any[]> {
    try {
      const startQueryCommand = new StartQueryCommand({
        logGroupNames: this.services.map(s => s.logGroup),
        startTime: Math.floor(startTime.getTime() / 1000),
        endTime: Math.floor(endTime.getTime() / 1000),
        queryString: query
      });

      const startResponse = await this.client.send(startQueryCommand);
      const queryId = startResponse.queryId;

      if (!queryId) {
        throw new Error('Failed to start query');
      }

      // Poll for results
      let status: QueryStatus = 'Running';
      let results: any[] = [];

      while (status === 'Running') {
        await new Promise(resolve => setTimeout(resolve, 1000)); // Wait 1 second
        
        const getResultsCommand = new GetQueryResultsCommand({ queryId });
        const response = await this.client.send(getResultsCommand);
        
        status = response.status || 'Failed';
        results = response.results || [];
      }

      if (status !== 'Complete') {
        throw new Error(`Query failed with status: ${status}`);
      }

      return results;
    } catch (error) {
      console.error('Error running insights query:', error);
      throw error;
    }
  }

  getServiceInfo(serviceName: string): ServiceInfo | undefined {
    return this.services.find(s => s.name === serviceName);
  }

  getAllServices(): ServiceInfo[] {
    return [...this.services];
  }
}