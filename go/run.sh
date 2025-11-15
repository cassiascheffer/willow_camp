#!/bin/bash

# Simple script to run the Go server

# Set DATABASE_URL if not already set
if [ -z "$DATABASE_URL" ]; then
    export DATABASE_URL="postgresql://localhost/willow_camp_development?sslmode=disable"
fi

# Set PORT if not already set
if [ -z "$PORT" ]; then
    export PORT="3001"
fi

echo "Starting WillowCamp Go server..."
echo "DATABASE_URL: $DATABASE_URL"
echo "PORT: $PORT"
echo ""
echo "Once started, you can access your blog at:"
echo "  http://localhost:$PORT"
echo ""

# Run the server
./bin/server
