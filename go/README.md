# WillowCamp Go

Go implementation of the WillowCamp blogging platform.

## Setup

```bash
# Install dependencies
go mod tidy

# Run server
go run cmd/server/main.go

# Build binary
go build -o bin/server cmd/server/main.go
```

## Environment Variables

- `DATABASE_URL` - PostgreSQL connection string (required)
- `PORT` - Server port (default: 3001)
- `SESSION_SECRET` - Secret key for session encryption (required in production)

## Development

The Go app shares the same PostgreSQL database as the Rails app.
