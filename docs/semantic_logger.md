# Rails Semantic Logger

Rails Semantic Logger has been added to replace the default Rails logger with structured logging capabilities.

## What's New

- **Structured logging**: Add key-value pairs to log messages
- **JSON output**: Automatic JSON formatting in production
- **Better performance**: Reduced memory usage vs default Rails logger
- **APM integration**: Works with existing Scout APM setup

## Configuration

### Application Config (`config/application.rb`)
```ruby
# Setup structured logging
config.semantic_logger.application = "willow_camp"
config.semantic_logger.environment = ENV["RAILS_ENV"] || Rails.env
config.log_level = ENV["LOG_LEVEL"] || :info

# JSON output for production or when LOG_TO_CONSOLE is set
if ENV["LOG_TO_CONSOLE"] || Rails.env.production?
  config.rails_semantic_logger.add_file_appender = false
  config.semantic_logger.add_appender(io: $stdout, formatter: :json)
end
```

### Environment Variables
- `LOG_LEVEL`: Set log level (debug, info, warn, error, fatal)
- `LOG_TO_CONSOLE`: Force JSON output to stdout

## Usage

### Basic Logging (same as before)
```ruby
Rails.logger.info "User logged in"
Rails.logger.error "Something went wrong"
```

### Structured Logging (new)
```ruby
Rails.logger.info "User action", user_id: 123, action: "login", ip: "192.168.1.1"
Rails.logger.error "Operation failed", error: e.message, user_id: current_user.id
```

## Output Formats

### Development
```
2025-07-07 08:21:43.227976 I [51780:1976 (willow-camp):1] Rails -- User logged in
```

### Production (JSON)
```json
{
  "host": "MacBookAir",
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

## Testing

```bash
# Test development logging
bundle exec rails console
Rails.logger.info("Test message")

# Test JSON output
LOG_TO_CONSOLE=true bundle exec rails console
Rails.logger.info("Test JSON message")
```

## Migration

No code changes required - existing `Rails.logger` calls work unchanged. You can optionally add structured data to new log statements for better observability.