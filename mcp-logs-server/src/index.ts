#!/usr/bin/env node

import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
  McpError,
  ErrorCode,
} from '@modelcontextprotocol/sdk/types.js';

import { CloudWatchService } from './utils/cloudwatch.js';
import { LogParser } from './utils/log-parser.js';
import { listServicesHandler } from './tools/list-services.js';
import { fetchLogsHandler } from './tools/fetch-logs.js';
import { searchLogsHandler } from './tools/search-logs.js';
import { streamLogsHandler } from './tools/stream-logs.js';
import { analyzeErrorsHandler } from './tools/analyze-errors.js';

class LogsServer {
  private server: Server;
  private cloudWatch: CloudWatchService;

  constructor() {
    this.server = new Server({
      name: 'logs-server',
      version: '1.0.0',
    });

    // Initialize CloudWatch service
    const region = process.env.AWS_REGION || 'us-east-1';
    this.cloudWatch = new CloudWatchService(region);

    this.setupHandlers();
  }

  private setupHandlers() {
    // List available tools
    this.server.setRequestHandler(ListToolsRequestSchema, async () => ({
      tools: [
        {
          name: 'list_services',
          description: 'List all available services and their log groups',
          inputSchema: {
            type: 'object',
            properties: {},
          },
        },
        {
          name: 'fetch_logs',
          description: 'Fetch logs from a specific service with optional filtering',
          inputSchema: {
            type: 'object',
            properties: {
              service: {
                type: 'string',
                description: 'Service name (user, messages, notifications, recruiting, clan-data)',
              },
              hours: {
                type: 'number',
                description: 'Number of hours back to search (default: 1)',
                default: 1,
              },
              limit: {
                type: 'number',
                description: 'Maximum number of log entries to return (default: 100)',
                default: 100,
              },
              filter: {
                type: 'string',
                description: 'CloudWatch filter pattern (optional)',
              },
            },
            required: ['service'],
          },
        },
        {
          name: 'search_logs',
          description: 'Search across all services or specific services for log entries',
          inputSchema: {
            type: 'object',
            properties: {
              query: {
                type: 'string',
                description: 'Search query or CloudWatch filter pattern',
              },
              services: {
                type: 'array',
                items: { type: 'string' },
                description: 'List of services to search in (optional, searches all if not specified)',
              },
              hours: {
                type: 'number',
                description: 'Number of hours back to search (default: 1)',
                default: 1,
              },
              limit: {
                type: 'number',
                description: 'Maximum number of log entries to return (default: 100)',
                default: 100,
              },
            },
            required: ['query'],
          },
        },
        {
          name: 'analyze_errors',
          description: 'Analyze error patterns and performance metrics from logs',
          inputSchema: {
            type: 'object',
            properties: {
              service: {
                type: 'string',
                description: 'Service name to analyze (optional, analyzes all if not specified)',
              },
              hours: {
                type: 'number',
                description: 'Number of hours back to analyze (default: 24)',
                default: 24,
              },
            },
          },
        },
        {
          name: 'stream_logs',
          description: 'Get recent logs from a service (tail-like functionality)',
          inputSchema: {
            type: 'object',
            properties: {
              service: {
                type: 'string',
                description: 'Service name to stream logs from',
              },
              lines: {
                type: 'number',
                description: 'Number of recent lines to fetch (default: 50)',
                default: 50,
              },
            },
            required: ['service'],
          },
        },
      ],
    }));

    // Handle tool calls
    this.server.setRequestHandler(CallToolRequestSchema, async (request) => {
      try {
        switch (request.params.name) {
          case 'list_services':
            return await listServicesHandler(this.cloudWatch);

          case 'fetch_logs':
            return await fetchLogsHandler(this.cloudWatch, request.params.arguments);

          case 'search_logs':
            return await searchLogsHandler(this.cloudWatch, request.params.arguments);

          case 'stream_logs':
            return await streamLogsHandler(this.cloudWatch, request.params.arguments);

          case 'analyze_errors':
            return await analyzeErrorsHandler(this.cloudWatch, request.params.arguments);

          default:
            throw new McpError(
              ErrorCode.MethodNotFound,
              `Unknown tool: ${request.params.name}`
            );
        }
      } catch (error) {
        console.error('Tool execution error:', error);
        if (error instanceof McpError) {
          throw error;
        }
        throw new McpError(
          ErrorCode.InternalError,
          `Tool execution failed: ${error instanceof Error ? error.message : String(error)}`
        );
      }
    });
  }

  async run() {
    const transport = new StdioServerTransport();
    await this.server.connect(transport);
    console.error('MCP Logs Server running on stdio');
  }
}

async function main() {
  const server = new LogsServer();
  await server.run();
}

if (import.meta.url === `file://${process.argv[1]}`) {
  main().catch((error) => {
    console.error('Server failed to start:', error);
    process.exit(1);
  });
}