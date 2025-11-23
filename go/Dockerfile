# Build stage
FROM golang:1.25-alpine AS builder

# Install build dependencies (git for go modules, nodejs and npm for frontend)
RUN apk add --no-cache git nodejs npm

WORKDIR /app

# Copy package files and install frontend dependencies
COPY package.json package-lock.json ./
RUN npm ci --production=false

# Copy frontend source files and config
COPY src ./src
COPY vite.config.js tailwind.config.js postcss.config.js ./
COPY static ./static

# Build frontend assets (outputs to static/dist/)
RUN npm run build

# Copy go mod files and download dependencies
COPY go.mod go.sum ./
RUN go mod download

# Copy Go source code
COPY cmd ./cmd
COPY internal ./internal

# Build the Go application
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o server ./cmd/server

# Runtime stage
FROM alpine:latest

RUN apk --no-cache add ca-certificates

WORKDIR /root/

# Copy the binary from builder
COPY --from=builder /app/server .

# Copy templates (needed for rendering)
COPY --from=builder /app/internal/templates ./internal/templates

# Copy icons (needed for template rendering)
COPY --from=builder /app/internal/icons ./internal/icons

# Copy static files including built frontend assets
COPY --from=builder /app/static ./static

# Expose port (Digital Ocean will set PORT env var)
EXPOSE 3001

# Run the application
CMD ["./server"]
