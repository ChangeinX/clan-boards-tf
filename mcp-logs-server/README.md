# MCP Logs Server

A Model Context Protocol (MCP) server for CloudWatch log collection and troubleshooting. This server provides tools to gather logs from your ECS services, search across multiple services, analyze error patterns, and stream recent logs for troubleshooting.

## Features

- **Service Discovery**: List all available services and their CloudWatch log groups
- **Log Retrieval**: Fetch logs from specific services with time range and filtering
- **Multi-Service Search**: Search across all services or specific ones with powerful query capabilities
- **Error Analysis**: Automatic error pattern detection, performance analysis, and troubleshooting insights
- **Log Streaming**: Tail-like functionality to view recent logs from services
- **Real-time Troubleshooting**: Comprehensive analysis tools for identifying issues

## Prerequisites

- Node.js 18+ with npm
- AWS credentials configured (via AWS CLI, environment variables, or IAM roles)
- Access to CloudWatch Logs in your AWS account
- MCP-compatible client (like Claude Desktop)

## Installation

1. **Clone and setup the server:**
   ```bash
   cd mcp-logs-server
   npm install
   npm run build
   ```

2. **Configure AWS credentials:**
   ```bash
   # Option 1: AWS CLI
   aws configure
   
   # Option 2: Environment variables
   export AWS_ACCESS_KEY_ID=your-access-key
   export AWS_SECRET_ACCESS_KEY=your-secret-key
   export AWS_REGION=us-east-1
   
   # Option 3: Use IAM roles (if running on EC2/ECS/Lambda)
   ```

3. **Configure your MCP client** (e.g., Claude Desktop):

   Add to your MCP configuration file:
   ```json
   {
     "mcpServers": {
       "logs-server": {
         "command": "node",
         "args": ["/path/to/clan-boards-tf/mcp-logs-server/dist/index.js"],
         "env": {
           "AWS_REGION": "us-east-1"
         }
       }
     }
   }
   ```

## Available Tools

### 1. `list_services`
List all available services and their log groups.

**Usage:**
```
list_services
```

**Output:** Shows all discoverable services with their CloudWatch log groups, ports, and descriptions.

### 2. `fetch_logs`
Fetch logs from a specific service with optional filtering.

**Parameters:**
- `service` (required): Service name (`user`, `messages`, `notifications`, `recruiting`, `clan-data`)
- `hours` (optional): Number of hours back to search (default: 1)
- `limit` (optional): Maximum entries to return (default: 100)
- `filter` (optional): CloudWatch filter pattern

**Usage:**
```
fetch_logs service="user" hours=2 limit=50 filter="ERROR"
```

### 3. `search_logs`
Search across all services or specific services for log entries.

**Parameters:**
- `query` (required): Search query or CloudWatch filter pattern
- `services` (optional): Array of service names to search in
- `hours` (optional): Number of hours back to search (default: 1)
- `limit` (optional): Maximum entries to return (default: 100)

**Usage:**
```
search_logs query="500 error" services=["user", "messages"] hours=6
```

### 4. `analyze_errors`
Comprehensive error analysis and performance insights.

**Parameters:**
- `service` (optional): Specific service to analyze (analyzes all if not specified)
- `hours` (optional): Number of hours back to analyze (default: 24)

**Usage:**
```
analyze_errors service="notifications" hours=12
```

**Output:** 
- Error pattern detection and categorization
- Performance metrics (response times, slow requests)
- HTTP status code distribution
- Service-specific breakdowns
- Recent slow requests with details

### 5. `stream_logs`
Get recent logs from a service (tail-like functionality).

**Parameters:**
- `service` (required): Service name to stream logs from
- `lines` (optional): Number of recent lines to fetch (default: 50)

**Usage:**
```
stream_logs service="messages" lines=100
```

## Configuration

### Environment Variables

- `AWS_REGION`: AWS region for CloudWatch Logs (default: us-east-1)
- `AWS_ACCESS_KEY_ID`: AWS access key (if not using other auth methods)
- `AWS_SECRET_ACCESS_KEY`: AWS secret key (if not using other auth methods)

### Service Configuration

The server is pre-configured for the following services:

| Service | Log Group | Port | Description |
|---------|-----------|------|-------------|
| user | /ecs/clan-boards-user | 8020 | User authentication service |
| messages | /ecs/clan-boards-messages | 8010 | Message processing service |
| notifications | /ecs/clan-boards-notifications | 8030 | Push notification service |
| recruiting | /ecs/clan-boards-recruiting | 8040 | Recruiting management service |
| clan-data | /ecs/clan-boards-clan-data | 8050 | Clan data aggregation service |

## Troubleshooting Use Cases

### 1. **Quick Service Health Check**
```
stream_logs service="user" lines=20
```
See the most recent activity from the user service.

### 2. **Error Investigation**
```
analyze_errors hours=6
```
Get a comprehensive overview of errors across all services in the last 6 hours.

### 3. **Specific Error Tracking**
```
search_logs query="500|ERROR|Exception" hours=12
```
Find all errors and exceptions across all services in the last 12 hours.

### 4. **Performance Issues**
```
analyze_errors service="messages" hours=24
```
Deep dive into the messages service performance and error patterns.

### 5. **Request Tracing**
```
search_logs query="request-id-abc123" services=["user", "messages"]
```
Follow a specific request across multiple services.

## Development

To run in development mode:
```bash
npm run dev
```

To build:
```bash
npm run build
```

## Security Considerations

- The server requires AWS CloudWatch Logs read permissions
- Ensure proper IAM roles/policies are configured
- Log data may contain sensitive information - secure your MCP client accordingly
- Consider using IAM roles instead of access keys when possible

## AWS IAM Permissions Required

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams",
        "logs:FilterLogEvents",
        "logs:StartQuery",
        "logs:GetQueryResults"
      ],
      "Resource": [
        "arn:aws:logs:*:*:log-group:/ecs/*",
        "arn:aws:logs:*:*:log-group:/ecs/*:log-stream:*"
      ]
    }
  ]
}
```

## Architecture

```
mcp-logs-server/
├── src/
│   ├── index.ts           # MCP server entry point
│   ├── tools/             # MCP tool implementations
│   │   ├── list-services.ts
│   │   ├── fetch-logs.ts
│   │   ├── search-logs.ts
│   │   ├── stream-logs.ts
│   │   └── analyze-errors.ts
│   ├── utils/             # Utility classes
│   │   ├── cloudwatch.ts  # AWS CloudWatch client
│   │   └── log-parser.ts  # Log parsing and analysis
│   └── types.ts          # TypeScript definitions
├── package.json
├── tsconfig.json
└── README.md
```

## Contributing

1. Follow TypeScript best practices
2. Add tests for new functionality
3. Update documentation for new tools or features
4. Ensure error handling and proper logging

## License

ISC