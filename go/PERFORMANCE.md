# Performance Optimizations

This document outlines the performance optimizations implemented in the Go application.

## Database Connection Pooling

The application uses pgxpool for efficient database connection management:

- **Max Connections**: 25 (adjust based on load)
- **Min Connections**: 5 (keeps connections warm)
- **Max Connection Lifetime**: 5 minutes
- **Max Connection Idle Time**: 1 minute

These settings balance performance with resource usage.

## HTTP Middleware

### Compression (Gzip)
All HTTP responses are compressed using gzip middleware, reducing bandwidth usage by 60-80% for text content.

### Security Headers
The Secure middleware adds security headers to prevent common attacks:
- X-Frame-Options
- X-Content-Type-Options
- X-XSS-Protection
- Strict-Transport-Security (in production with HTTPS)

## Caching Strategy

### Static Assets
Static files are served with appropriate cache headers. In production, consider using a CDN for:
- `/static/*` - Application CSS/JS
- `/openmoji-*` - Emoji assets

### Database Queries
- Uses prepared statements via pgx
- Connection pooling reduces overhead
- Efficient query patterns in repositories

## Load Testing

To load test the application:

```bash
# Install hey (HTTP load generator)
go install github.com/rakyll/hey@latest

# Test homepage
hey -n 10000 -c 50 http://localhost:3001/

# Test authenticated endpoints
hey -n 5000 -c 25 -H "Cookie: session=..." http://localhost:3001/dashboard
```

## Performance Benchmarks

Target metrics for production:
- **Response time (p95)**: < 100ms for cached content
- **Response time (p95)**: < 300ms for database queries
- **Throughput**: > 1000 req/s on modest hardware
- **Database pool utilization**: < 80% under normal load

## Production Recommendations

1. **Enable HTTP/2**: Use a reverse proxy (nginx/Caddy) with HTTP/2
2. **Add CDN**: Serve static assets through CloudFlare or similar
3. **Database**: Use read replicas for high-traffic blogs
4. **Monitoring**: Add Prometheus metrics for observability
5. **Rate limiting**: Implement per-IP rate limiting for public endpoints
