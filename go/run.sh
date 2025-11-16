#!/bin/bash

# Script to run both Vite dev server and Go server

# Set DATABASE_URL if not already set
if [ -z "$DATABASE_URL" ]; then
    export DATABASE_URL="postgresql://localhost/willow_camp_development?sslmode=disable"
fi

# Set PORT if not already set
if [ -z "$PORT" ]; then
    export PORT="3001"
fi

# Cleanup function to kill background processes
cleanup() {
    echo ""
    echo "Shutting down..."
    if [ ! -z "$GO_PID" ]; then
        kill $GO_PID 2>/dev/null
    fi
    exit
}

# Set trap to cleanup on script exit
trap cleanup INT TERM EXIT

echo "Starting WillowCamp development environment..."
echo "DATABASE_URL: $DATABASE_URL"
echo "PORT: $PORT"
echo ""

# Build frontend assets first
echo "Building frontend assets..."
npm run build
if [ $? -ne 0 ]; then
    echo "Failed to build frontend assets"
    exit 1
fi
echo "Frontend build complete!"
echo ""

# Build the Go server
echo "Building Go server..."
go build -o bin/server ./cmd/server
if [ $? -ne 0 ]; then
    echo "Failed to build Go server"
    exit 1
fi
echo "Build complete!"
echo ""

# Start Go server in the background
echo "Starting Go server..."
./bin/server &
GO_PID=$!
echo "Go server running (PID: $GO_PID)"
echo "Once started, you can access your blog at:"
echo "  http://localhost:$PORT"
echo ""

# Give Go server a moment to start
sleep 2

echo "Starting Vite dev server..."
echo ""

# Run Vite in the foreground
npm run dev
