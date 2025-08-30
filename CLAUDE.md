# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

### Development
- `bin/dev` - Start Rails server and Tailwind CSS watcher
- `rails server` - Start Rails server only
- `rails console` - Rails interactive console

### Testing
- `rails test` - Run all tests
- `rails test test/path/to/test.rb` - Run specific test file
- `rails test test/path/to/test.rb:LINE` - Run specific test at line number

### Code Quality
- `standardrb` - Run Ruby style checker and formatter
- `standardrb --fix` - Auto-fix Ruby style issues
- `bin/brakeman` - Run security scanner

### Database
- `rails db:migrate` - Run pending migrations
- `rails db:rollback` - Rollback last migration
- `rails db:seed` - Load seed data
- `rails db:reset` - Drop, create, migrate, and seed database

### Deployment
- `bin/kamal deploy` - Deploy using Kamal (Docker-based deployment)
- `rails assets:precompile` - Compile assets for production

## Architecture

This is a multi-tenant blogging platform built with Rails 8.0.2 following standard MVC patterns.

### Key Components

**Multi-tenancy**: Each user gets a subdomain (username.willow.camp) and can configure custom domains. Tenant isolation is handled through current_user scoping in controllers.

**Authentication**: Session-based for web interface, token-based for API. UserToken model handles API authentication with bearer tokens.

**Content Management**: Posts are stored as Markdown with YAML frontmatter. The PostMarkdown library (app/lib/post_markdown.rb) handles parsing and validation. Services in app/services/ handle conversion between Post models and Markdown.

**Frontend**: Uses Hotwire (Turbo + Stimulus) for interactivity without a JavaScript build step. Import maps manage JavaScript modules. Tailwind CSS with DaisyUI provides styling and theme support. Icons are provided by the heroicons gem with view helpers like `<%= heroicon "icon-name" %>`.

**API**: RESTful JSON API under /api namespace. All endpoints require authentication and return consistent error formats.

### Database Structure

Uses PostgreSQL with UUID primary keys. Additional databases configured for:
- solid_cache: Database-backed caching
- solid_queue: Database-backed job queue
- solid_cable: Database-backed ActionCable

### Request Flow

1. Subdomain/domain routing determines the blog being accessed
2. Controllers use before_action callbacks to set current blog context
3. Blog namespace handles public-facing content
4. Dashboard namespace handles authenticated user actions
5. API namespace handles programmatic access

### Testing Approach

Uses Rails default Minitest framework. Tests are organized by type:
- test/models/ - Model unit tests
- test/controllers/ - Controller tests
- test/system/ - Full-stack browser tests with Capybara

### Deployment

Configured for containerized deployment using Kamal. The Dockerfile and docker-compose.yml handle production setup. Environment variables are managed through Rails credentials.
- We are in the middle of a migration. Users used to have blog metadata as attributes on their record. Now each user has many blogs. We have not run the migration in production yet. Any work we do should keep the models backwawrds-compatible. We can change controllers viewss and routes to not be backwards compatible.