# Production Deployment Checklist

This checklist ensures the Go application is production-ready.

## Pre-Deployment Checklist

### Environment Variables
- [ ] `DATABASE_URL` - PostgreSQL connection string
- [ ] `SESSION_SECRET` - Strong random secret (min 32 characters)
- [ ] `PORT` - Port to listen on (default: 3001)

### Security
- [ ] SESSION_SECRET uses cryptographically secure random value
- [ ] Database uses SSL/TLS connections (`?sslmode=require`)
- [ ] HTTPS enabled via reverse proxy
- [ ] Security headers configured (Secure middleware enabled)
- [ ] CORS configured for allowed origins only
- [ ] Rate limiting implemented at proxy level

### Database
- [ ] Migrations applied to production database
- [ ] Database backup strategy in place
- [ ] Connection pool sized appropriately (see PERFORMANCE.md)
- [ ] Database monitoring enabled
- [ ] Read replicas configured (if needed for scale)

### Application
- [ ] Build tested with `go build ./cmd/server`
- [ ] All tests passing
- [ ] Static assets accessible
- [ ] Templates accessible
- [ ] Health check endpoint responding (`/health`)

### Infrastructure
- [ ] Reverse proxy configured (nginx/Caddy)
- [ ] SSL certificates installed and auto-renewing
- [ ] CDN configured for static assets (optional but recommended)
- [ ] Log aggregation set up
- [ ] Monitoring and alerting configured
- [ ] Backup and disaster recovery plan documented

## Deployment Steps

### Using Docker

1. Build the Docker image:
```bash
docker build -t willow-camp-go:latest .
```

2. Run with environment variables:
```bash
docker run -d \
  -p 3001:3001 \
  -e DATABASE_URL="postgresql://user:pass@host:5432/db?sslmode=require" \
  -e SESSION_SECRET="your-secure-random-secret" \
  --name willow-camp \
  willow-camp-go:latest
```

### Using Docker Compose

1. Create production `.env` file with required variables

2. Deploy:
```bash
docker-compose up -d
```

### Manual Deployment

1. Build the application:
```bash
CGO_ENABLED=0 go build -o server -ldflags="-s -w" ./cmd/server
```

2. Copy files to server:
```bash
scp server user@host:/opt/willow-camp/
scp -r internal/templates user@host:/opt/willow-camp/
scp -r static user@host:/opt/willow-camp/
```

3. Create systemd service (`/etc/systemd/system/willow-camp.service`):
```ini
[Unit]
Description=Willow Camp Go Server
After=network.target postgresql.service

[Service]
Type=simple
User=willow-camp
WorkingDirectory=/opt/willow-camp
Environment=DATABASE_URL=postgresql://...
Environment=SESSION_SECRET=...
Environment=PORT=3001
ExecStart=/opt/willow-camp/server
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
```

4. Enable and start:
```bash
sudo systemctl enable willow-camp
sudo systemctl start willow-camp
```

## Post-Deployment Verification

- [ ] Health check responds: `curl https://yoursite.com/health`
- [ ] Login page loads
- [ ] Can authenticate successfully
- [ ] Dashboard loads
- [ ] Can create/edit/delete posts
- [ ] Public blog pages render correctly
- [ ] RSS feed generates
- [ ] Sitemap generates
- [ ] Static assets load (check browser DevTools)
- [ ] No errors in application logs
- [ ] Database connections within limits
- [ ] Response times meet SLA (see PERFORMANCE.md)

## Rollback Plan

If deployment fails:

1. Stop the new version:
```bash
docker stop willow-camp
# or
sudo systemctl stop willow-camp
```

2. Start previous version:
```bash
docker start willow-camp-old
# or redeploy previous version
```

3. Investigate logs:
```bash
docker logs willow-camp
# or
sudo journalctl -u willow-camp -n 100
```

## Monitoring

Key metrics to monitor:
- HTTP response times (p50, p95, p99)
- Error rates (4xx, 5xx)
- Database connection pool usage
- Memory and CPU usage
- Disk I/O and space

## Support

- Application logs: Check stdout/stderr or log aggregation system
- Database logs: Check PostgreSQL logs
- Reverse proxy logs: Check nginx/Caddy access and error logs
