# Rate Limiting with Rack::Attack

This application uses Rack::Attack middleware to protect against abusive requests and implement rate limiting.

## How It Works

Rack::Attack evaluates incoming requests against configured rules and can throttle or block requests that exceed defined limits. The middleware runs early in the request pipeline to minimize resource usage from abusive clients.

## Logging

Rate limited requests are logged with structured data for monitoring and analysis:

```ruby
Rails.logger.warn("[Rack::Attack] Request throttled: #{request_info.to_json}")
```

### Logged Information

When a request is throttled, the following data is captured:
- `timestamp`: ISO8601 timestamp of the event
- `event`: Type of event (throttled/blocked)
- `matched_rule`: The Rack::Attack rule that was triggered
- `discriminator`: The value used for rate limiting (e.g., IP address, user email)
- `match_data`: Additional data from the rule match
- `ip`: Client IP address
- `path`: Request path
- `method`: HTTP method
- `user_agent`: Client user agent string
- `referer`: HTTP referer
- `subdomain`: Request subdomain
- `host`: Full host header

### Privacy Protection

The logging middleware automatically obfuscates email addresses to protect user privacy:
- Email format: `f***o@example.com` (first and last characters preserved)
- Short usernames are fully masked for better privacy

## Configuration

Rate limiting rules are configured in `config/initializers/rack_attack.rb`. Common patterns include:

- **Request throttling**: Limit requests per IP/user over time windows
- **Login protection**: Prevent brute force attacks on authentication endpoints
- **API rate limiting**: Control API usage per token/user
- **Blocklisting**: Permanently block known bad actors

## Monitoring

Monitor rate limiting effectiveness through:
1. Application logs for throttled request patterns
2. Error tracking (Honeybadger) for any middleware errors
3. Performance monitoring for request latency impacts

## Response Headers

Throttled requests receive:
- HTTP 429 (Too Many Requests) status code
- `Retry-After` header indicating when to retry
- JSON error response with rate limit details

## Best Practices

1. **Set reasonable limits**: Balance security with legitimate usage patterns
2. **Monitor false positives**: Review logs for legitimate users being throttled
3. **Use appropriate discriminators**: IP for anonymous users, user ID for authenticated
4. **Implement exponential backoff**: Increase penalties for repeat offenders
5. **Whitelist known good actors**: Exclude monitoring services, internal IPs

## Testing Rate Limits

```bash
# Test rate limiting locally
for i in {1..100}; do
  curl -I http://localhost:3000/api/posts
  sleep 0.1
done

# Check logs for throttled requests
rails log | grep "Rack::Attack"
```

## Troubleshooting

If legitimate users are being rate limited:
1. Check the matched rule in logs
2. Review the discriminator (IP vs user-based)
3. Adjust limits in rack_attack.rb
4. Consider whitelisting specific IPs or users