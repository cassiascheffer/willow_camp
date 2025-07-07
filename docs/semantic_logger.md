# Logging System

This application uses Rails Semantic Logger for structured logging with enhanced observability features.

## How It Works

The logging system automatically captures structured data from your application and forwards it to multiple destinations:

- **File logs**: Written to `log/` directory in development and test
- **JSON output**: Structured logs to stdout in production
- **Honeybadger Insights**: Centralized log aggregation and analysis
- **Scout APM**: Performance monitoring integration

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
JSON format for machine processing:
```json
{
  "host": "server-01",
  "application": "willow_camp",
  "environment": "production",
  "timestamp": "2025-07-07T12:22:08.720152Z",
  "level": "info",
  "pid": 51819,
  "name": "Rails",
  "message": "User action",
  "user_id": 123,
  "action": "login"
}
```

## Environment Variables

- `LOG_LEVEL`: Control verbosity (debug, info, warn, error, fatal)
- `LOG_TO_CONSOLE`: Force JSON output to stdout
- `RAILS_ENV`: Determines output format and destinations

## Observability Features

### Honeybadger Insights
All logs are automatically sent to Honeybadger for:
- Centralized log search and filtering
- Error correlation with application traces
- Performance analysis and alerting

### Scout APM Integration
Logs are correlated with performance metrics:
- Request tracing
- Database query analysis
- Memory and CPU usage tracking

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
# Test basic logging
rails console
Rails.logger.info("Test message")

# Test JSON output
LOG_TO_CONSOLE=true rails console
Rails.logger.info("Test JSON message")
```

## Migration Notes

Existing `Rails.logger` calls work unchanged. You can gradually add structured data to improve observability without breaking existing functionality.