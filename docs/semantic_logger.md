# Logging System

This application uses Rails Semantic Logger for structured logging with enhanced observability.

## How It Works

The logging system automatically captures structured data from your application and forwards it to multiple destinations:

- **Console output**: Colored format in development for readability
- **JSON output**: Structured logs to stdout in production for easy parsing and aggregation

## Log Levels

Standard Rails log levels are supported:
- `debug` - Detailed diagnostic information
- `info` - General informational messages
- `warn` - Warning conditions
- `error` - Error conditions
- `fatal` - Critical errors

Set log level with `LOG_LEVEL` environment variable.

## Basic Logging

```ruby
Rails.logger.info "User logged in"
Rails.logger.error "Something went wrong"
```

## Structured Logging

Add key-value pairs to provide context:

```ruby
Rails.logger.info "User action", 
  user_id: current_user.id, 
  action: "login", 
  ip: request.remote_ip

Rails.logger.error "Operation failed", 
  error: e.message, 
  user_id: current_user.id,
  operation: "post_creation"
```

## Log Output

### Development Environment
Human-readable format with timestamps:
```
2025-07-07 08:21:43.227976 I [51780:1976 (willow-camp):1] Rails -- User logged in
```

### Production Environment
JSON format for structured logging:
```json
{
  "host": "server-01",
  "application": "willow_camp",
  "environment": "production",
  "timestamp": "2025-07-07T12:22:08.720Z",
  "level": "info",
  "level_index": 2,
  "pid": 51819,
  "thread": "70123456789",
  "name": "Rails",
  "message": "User action",
  "user_id": 123,
  "action": "login"
}
```

## Environment Variables

- `LOG_LEVEL`: Control verbosity (debug, info, warn, error, fatal)
- `DISABLE_SQL_LOGGING`: Disable SQL query logging in production
- `RAILS_ENV`: Determines output format and destinations

## Observability Features

### Log Aggregation
The application outputs standard JSON logs that can be ingested by any log aggregation service:
- **JSON format**: All production logs are output as structured JSON
- **Searchable**: Structured data enables powerful querying and filtering
- **Error tracking**: Errors are tracked separately via Honeybadger integration

### Error Monitoring
Honeybadger handles error tracking separately from logs:
- Exception capture and alerting
- Error grouping and trends

## Best Practices

### Use Structured Data
```ruby
# Good - provides searchable context
logger.info "Order processed", 
  order_id: order.id, 
  amount: order.total, 
  user_id: order.user_id

# Avoid - harder to search and analyze
logger.info "Order #{order.id} for $#{order.total} processed"
```

### Choose Appropriate Levels
- Use `info` for business events (user actions, state changes)
- Use `warn` for recoverable issues (deprecated features, fallbacks)
- Use `error` for exceptions and failures
- Use `debug` for detailed diagnostic information

### Include Context
Always include relevant identifiers (user_id, order_id, etc.) to help with debugging and analysis.

## Request Logging

The system automatically logs HTTP requests with:
- Request method and path
- Response status and duration
- User agent and IP address
- Controller and action names

No additional code required - this happens automatically.

## Testing Logs

```bash
# Test basic logging in development
rails console
Rails.logger.info("Test message", user_id: 123, action: "test")

# Test production JSON format locally
RAILS_ENV=production rails console
Rails.logger.info("Test JSON message", user_id: 123)
```

## Configuration Details

### Development
- Colored console output for readability
- Filters out noisy Rails logs (ActiveView renders, SQL queries)
- Shows warnings and above in test environment

### Production
- JSON output to stdout using Rails Semantic Logger JSON formatter
- Standard JSON formatting for log aggregation compatibility
- Optional SQL query logging control via DISABLE_SQL_LOGGING

## Migration Notes

Existing `Rails.logger` calls work unchanged. The system now:
- Uses structured JSON logging for better observability
- Uses Honeybadger exclusively for error tracking
- Provides consistent structured data for all log entries

Gradually add structured data to improve observability without breaking existing functionality.