# Willow Camp - Go Implementation

Go implementation of the Willow Camp multi-tenant blogging platform.

## Features

- **Multi-tenant architecture**: Each blog is isolated by subdomain or custom domain
- **Markdown posts**: Write posts in Markdown with GitHub Flavored Markdown support
- **Tag system**: Organize posts with tags and tag filtering
- **RSS feeds**: Auto-generated RSS/Atom feeds
- **SEO optimized**: Sitemap, meta descriptions, robots.txt
- **Session-based auth**: Secure authentication with bcrypt
- **Dashboard**: Full-featured admin interface
- **Flash messages**: User feedback via session-based flash messages
- **Docker ready**: Production-ready Dockerfile and docker-compose

## Quick Start

### Prerequisites

- Go 1.25 or later
- PostgreSQL 14 or later
- (Optional) Docker and Docker Compose

### Local Development

1. Set up environment variables:
```bash
export DATABASE_URL="postgresql://postgres:password@localhost:5432/willow_camp_development?sslmode=disable"
export SESSION_SECRET="dev-secret-change-in-production"
export PORT="3001"
```

2. Run database migrations (from Rails app):
```bash
cd ..
rails db:migrate
```

3. Build and run:
```bash
go build -o server ./cmd/server
./server
```

4. Visit http://localhost:3001

### Using Docker

```bash
docker-compose up
```

## Project Structure

```
go/
├── cmd/
│   └── server/          # Application entry point
├── internal/
│   ├── auth/            # Authentication service
│   ├── flash/           # Flash message system
│   ├── handlers/        # HTTP handlers
│   ├── logging/         # Structured logging
│   ├── middleware/      # HTTP middleware
│   ├── models/          # Data models
│   ├── repository/      # Database repositories
│   ├── templates/       # HTML templates
│   └── icons/           # Icon generation
├── static/              # Static assets (CSS, JS)
├── Dockerfile           # Production container
├── docker-compose.yml   # Local development
├── DEPLOYMENT.md        # Production deployment guide
└── PERFORMANCE.md       # Performance optimization guide
```

## API Endpoints

### Public Routes

- `GET /` - Blog index (multi-tenant via subdomain)
- `GET /:slug` - Post detail page
- `GET /tags` - Tag index
- `GET /tags/:tag_slug` - Posts by tag
- `GET /feed.xml` - RSS/Atom feed
- `GET /sitemap.xml` - Sitemap
- `GET /robots.txt` - Robots.txt

### Authentication

- `GET /login` - Login page
- `POST /login` - Submit login
- `GET/POST /logout` - Logout

### Dashboard (Protected)

- `GET /dashboard` - Dashboard home
- `GET /dashboard/blogs/:blog_id/posts` - Post list
- `POST /dashboard/blogs/:blog_id/posts/untitled` - Create untitled draft and redirect to edit
- `GET /dashboard/blogs/:blog_id/posts/:post_id/edit` - Edit post form
- `POST/PUT /dashboard/blogs/:blog_id/posts/:post_id` - Update post
- `POST /dashboard/blogs/:blog_id/posts/:post_id/delete` - Delete post
- `GET /dashboard/blogs/:blog_id/settings` - Blog settings
- `POST /dashboard/blogs/:blog_id/settings` - Update blog settings
- `GET /dashboard/settings` - User settings
- `POST /dashboard/settings` - Update user settings
- `POST /dashboard/settings/password` - Change password

### Health Check

- `GET /health` - Health status (returns JSON)

## Configuration

### Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `DATABASE_URL` | Yes | - | PostgreSQL connection string |
| `SESSION_SECRET` | No | dev-secret | Secret for session encryption (use strong value in production) |
| `PORT` | No | 3001 | HTTP server port |

### Database Connection Pool

Configured in `cmd/server/main.go`:
- Max connections: 25
- Min connections: 5
- Max connection lifetime: 5 minutes
- Max idle time: 1 minute

See `PERFORMANCE.md` for tuning guidance.

## Development

### Generate Icons

Icons are generated from Heroicons:

```bash
cd internal/icons/generate
go generate .
```

### Run Tests

```bash
go test ./...
```

### Build

```bash
# Development build
go build -o server ./cmd/server

# Production build (smaller binary)
CGO_ENABLED=0 go build -o server -ldflags="-s -w" ./cmd/server
```

## Deployment

See `DEPLOYMENT.md` for complete production deployment checklist and instructions.

### Quick Deploy with Docker

```bash
docker build -t willow-camp:latest .
docker run -d -p 3001:3001 \
  -e DATABASE_URL="postgresql://..." \
  -e SESSION_SECRET="..." \
  willow-camp:latest
```

## Performance

- Gzip compression enabled
- Connection pooling for database
- Security headers configured
- Graceful shutdown support

See `PERFORMANCE.md` for optimization details and load testing guidance.

## License

See parent repository for license information.
