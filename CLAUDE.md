# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Willow Camp is a multi-tenant blogging platform built with Ruby on Rails. Users can create blogs that are accessible via:
- Subdomains: `{subdomain}.willow.camp`
- Custom domains: `custom-domain.com`

## Development Commands

### Running the Application

```bash
bin/dev                    # Start development server with all processes
rails server               # Start Rails server only (port 3000)
```

### Database

```bash
rails db:setup             # Create database, load schema, seed data
rails db:migrate           # Run pending migrations
rails db:migrate:status    # Check migration status
```

### Testing

```bash
bin/test                   # Run all tests (suppresses Ruby warnings)
rails test                 # Alternative: run tests with Rails directly
rails test test/models/post_test.rb              # Run specific test file
rails test test/models/post_test.rb:12           # Run specific test by line number
```

### Code Quality

```bash
bundle exec standardrb --fix                      # Auto-fix Ruby style issues
bundle exec standardrb --fix path/to/file.rb      # Fix specific file
bundle exec htmlbeautifier app/views/**/*.html.erb  # Format ERB files
bin/brakeman -q --no-pager                        # Run security scanner
```

### CLI Development

The CLI is a separate Ruby gem in `cli/`:

```bash
cd cli
bundle install
bundle exec rake test      # Run CLI tests
gem build willow_camp_cli.gemspec  # Build the gem
```

## Architecture

### Multi-Tenancy Model

The application uses a **Blog-based multi-tenancy** system:

- `User` → has many `Blog`s (max 2 per user)
- `Blog` → has many `Post`s and `Page`s
- Each blog can be accessed via subdomain OR custom domain
- Domain routing is handled by `DomainConstraint` in `config/routes.rb`

**Domain Resolution Flow:**
1. Request arrives with host (e.g., `myblog.willow.camp` or `custom-domain.com`)
2. `DomainConstraint` checks if host is valid
3. `Blogs::BaseController` sets `@blog` via `Blog.by_domain(request.host)`
4. `SecureDomainRedirect` concern handles custom domain redirects
5. All blog content is scoped to the resolved `@blog`

### Controller Hierarchy

```
ApplicationController
├─ Dashboard::BaseController → dashboard routes (authenticated users)
│  └─ Dashboard::BlogBaseController → blog-scoped dashboard routes
├─ Blogs::BaseController → public blog routes (uses blog layout)
│  ├─ Blogs::PostsController
│  ├─ Blogs::TagsController
│  └─ Blogs::FeedController
└─ Api::BaseController → API routes (token authentication)
   └─ Api::PostsController
```

### Post/Page System

`Post` and `Page` use **Single Table Inheritance**:
- Both share the same database table
- Differentiated by the `type` column
- `Page` inherits from `Post` with specialized behaviour
- Posts use FriendlyId for slug-based routing (scoped to blog)

### Markdown Processing

Posts are stored and managed as markdown with YAML frontmatter:

1. **Input**: Markdown file with frontmatter
2. **Parsing**: `UpdatePostFromMd` service extracts frontmatter and content
3. **Rendering**: `PostMarkdown` converts markdown to HTML (via Commonmarker)
4. **Storage**:
   - `body_markdown` stores raw markdown
   - `body_content` stores rendered HTML (ActionText rich text)
   - Mermaid diagrams detected and flagged via `has_mermaid_diagrams`

**Key classes:**
- `Post.from_markdown(content, blog, author)` - Create post from markdown
- `UpdatePostFromMd` - Service to parse frontmatter and update post attributes
- `PostMarkdown` - Convert markdown to HTML with mermaid support
- `PostToMarkdown` - Export post back to markdown format

### Database Configuration

Uses Rails 8 multiple databases for different concerns:
- `primary` - Main application data (users, blogs, posts)
- `cache` - Solid Cache storage
- `queue` - Solid Queue background jobs
- `cable` - Solid Cable WebSocket connections

## API

Token-based authentication for programmatic access:
- Create tokens at `/dashboard/settings`
- Include header: `Authorization: Bearer {token}`
- Endpoints: `/api/posts` (CRUD operations)
- See README.md for full API documentation

## Pre-commit Hooks (Lefthook)

The `lefthook.yml` configuration runs on every commit:

**Pre-commit:**
- StandardRB (auto-fix Ruby files)
- HTMLBeautifier (auto-fix ERB files)
- Brakeman security scanner
- Database migration status check

**Pre-push:**
- All tests must pass (`bin/test`)
- No uncommitted changes allowed
- Bundle check for dependency issues

If hooks fail with auto-fixes, review changes and re-stage files.

## Development Conventions

### Spelling
- Code (variables, methods): American spelling (`color`, `behavior`)
- Documentation and commits: Canadian spelling (`colour`, `behaviour`)

### Model Patterns

**ABOUTME comments**: Some files include `# ABOUTME:` comments at the top describing their purpose.

**Service objects**: Complex operations extracted to `app/services/`:
- `UpdatePostFromMd` - Parse markdown and update post
- `PostToMarkdown` - Export post to markdown format
- `ImageProcessor` - Handle image uploads and transformations

**Concerns**: Shared controller behaviour in `app/controllers/concerns/`:
- `SecureDomainRedirect` - Handle custom domain redirects with security checks

## Testing

Run tests frequently - all three types are required:
- Unit tests (`test/models/`, `test/lib/`)
- Controller tests (`test/controllers/`)
- System tests (`test/system/`)

Use Capybara + Cuprite for system testing (headless Chrome).
