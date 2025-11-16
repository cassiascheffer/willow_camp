# CLAUDE.md - Go Migration

This file provides guidance for working with the Go migration of Willow Camp.

## Project Overview

This directory contains an in-progress migration of Willow Camp from Ruby on Rails to Go. The goal is to achieve feature parity with the Rails application while improving performance and reducing operational complexity.

**Status**: Active development - implementing dashboard and post management features.

## Why Go?

- Better performance for serving blog content
- Lower memory footprint
- Simpler deployment (single binary)
- Strong concurrency primitives for handling multiple blogs

## Architecture

### Technology Stack

- **Web Framework**: Echo v4
- **Database**: PostgreSQL (same database as Rails, shared schema)
- **Templates**: Go html/template (matching DaisyUI styling from Rails)
- **Authentication**: Session-based with bcrypt (compatible with Rails Devise)
- **Icons**: Heroicons (embedded SVGs, matching Rails)
- **Frontend Build**: Vite + Tailwind CSS + DaisyUI + Alpine.js

### Directory Structure

```
go/
├── cmd/server/           # Application entry point
├── internal/
│   ├── auth/            # Authentication (session management, bcrypt)
│   ├── handlers/        # HTTP handlers (blog, dashboard, auth)
│   ├── middleware/      # Blog resolver, etc.
│   ├── models/          # Data models (matching Rails schema)
│   ├── repository/      # Database access layer (pgx)
│   ├── markdown/        # Markdown rendering (goldmark)
│   ├── helpers/         # Utility functions
│   ├── templates/       # Go templates (layout, pages)
│   └── icons/           # Generated heroicons (see below)
├── src/                 # Frontend source files
│   ├── main.js          # JavaScript entry point (Alpine.js)
│   └── main.css         # CSS entry point (Tailwind directives)
├── static/              # Static assets
│   ├── accessibility.css    # Accessibility styles (imported by main.css)
│   └── dist/            # Built frontend assets (gitignored)
│       ├── main.css     # Compiled CSS bundle
│       └── main.js      # Compiled JS bundle
├── go.mod               # Go module dependencies
├── package.json         # Frontend dependencies
├── vite.config.js       # Vite build configuration
├── tailwind.config.js   # Tailwind CSS configuration
├── postcss.config.js    # PostCSS configuration
└── CLAUDE.md           # This file
```

## Development Commands

### Frontend Build

**First time setup**: Install frontend dependencies:

```bash
cd go
npm install
```

**Build frontend assets**:

```bash
# Development build with watch mode
npm run dev

# Production build
npm run build
```

The build outputs to `static/dist/` which is served by the Go server at `/static/dist/`.

**Important**: You must build the frontend assets before running the server, otherwise CSS/JS will not load.

### Building the Go Server

```bash
cd go
go build -o server ./cmd/server     # Build the server binary
./server                             # Run the server (requires DATABASE_URL)
```

### Running in Development

**Option 1: Use the run script (recommended)**

The easiest way to run both Vite and Go together:

```bash
cd go
./run.sh
```

This script:
- Starts Vite dev server in the background
- Starts the Go server in the foreground
- Handles cleanup when you press Ctrl+C (kills both processes)
- Uses default DATABASE_URL if not set

**Option 2: Run in separate terminals**

**Terminal 1** - Frontend build with watch mode:
```bash
cd go
npm run dev
```

**Terminal 2** - Go server:
```bash
cd go
export DATABASE_URL="postgres://user:pass@localhost/willow_camp_development"
export SESSION_SECRET="your-secret-here"
export PORT="3001"  # Optional, defaults to 3001
./server
```

The server will run on `http://localhost:3001` (or the port you specify).

### Production Build

For production, build the frontend once:

```bash
cd go
npm run build      # Build frontend assets to static/dist/
go build -o server ./cmd/server
./server
```

### Icons Generation

**Important**: The `internal/icons/` directory contains generated code that is gitignored.

#### How Icons Work

1. **Source**: Icon definitions in `internal/icons/generate/main.go`
2. **Generator**: Uses `github.com/patrickward/go-heroicons` to fetch and embed SVGs
3. **Output**: Creates `provider.go` and SVG files in `internal/icons/`
4. **Ignored**: All generated files are in `.gitignore` (must regenerate after clone)

#### Generating Icons

```bash
cd go
go run ./internal/icons/generate
```

This will:
- Download heroicons from GitHub to `/tmp/heroicons`
- Generate `internal/icons/provider.go` with embedded SVGs
- Create `internal/icons/icons/*.svg` files
- Create `internal/icons/custom/missing.svg` fallback

**You must run this after**:
- Cloning the repository
- Adding new icons to the generator
- Switching between commits that change icon requirements

#### Adding New Icons

Edit `internal/icons/generate/main.go` and add to the `Icons` slice:

```go
{Name: "your-icon-name", Type: heroicons.IconOutline},  // 24px outline
{Name: "your-icon-name", Type: heroicons.IconMini},     // 20px solid
```

Then regenerate with `go run ./internal/icons/generate`.

#### Troubleshooting Icons

**Error**: `no required module provides package github.com/cassiascheffer/willow_camp/internal/icons`

**Solution**: Icons haven't been generated yet. Run:
```bash
go run ./internal/icons/generate
go build -o server ./cmd/server
```

**Why are icons gitignored?**
- Generated files should be reproducible
- Reduces repository size
- Generator pulls latest heroicons automatically
- Prevents merge conflicts in generated code

## Database

### Shared Schema

The Go application uses the **same PostgreSQL database** as the Rails application. The schema is managed by Rails migrations.

**Important**: 
- Do NOT create Go-specific migrations
- Let Rails manage the schema
- Go code reads from existing tables

### Connection

Uses `pgx/v5` driver with connection pooling. The `DATABASE_URL` environment variable should point to the same database Rails uses.

## Templates

### Template System

Go uses `html/template` with two layouts:
- `simple_layout.html` - For auth pages (login, etc.)
- `dashboard_layout.html` - For authenticated dashboard pages
- `layout.html` - For public blog pages

### Template Functions

Custom functions available in templates:
- `heroicon` - Render outline heroicon: `{{heroicon "check" "h-5 w-5"}}`
- `heroiconMini` - Render mini heroicon: `{{heroiconMini "check" "h-4 w-4"}}`
- `add` - Add two integers: `{{add .CurrentPage 1}}`
- `sub` - Subtract integers: `{{sub .CurrentPage 1}}`

### Matching Rails UI

Templates use DaisyUI classes to match the Rails application exactly:
- Same component styling
- Same responsive breakpoints (lg: prefix)
- Same color scheme and themes
- Same navigation structure

### Frontend Asset Pipeline

The Go app uses **Vite** for frontend builds, replacing CDN links:

**Development workflow**:
1. Edit CSS in `src/main.css` or JS in `src/main.js`
2. Vite watches for changes and rebuilds automatically
3. Refresh browser to see changes

**How it works**:
- `src/main.js` imports `src/main.css` and Alpine.js
- `src/main.css` includes Tailwind directives and accessibility styles
- Vite bundles everything to `static/dist/main.css` and `static/dist/main.js`
- Templates reference the built assets at `/static/dist/`
- Tailwind scans `internal/templates/**/*.html` for classes to include

**Built assets are gitignored** - you must run `npm run build` after cloning.

## Migration Progress

### Completed Features

- ✅ Database connection and repository layer
- ✅ Multi-tenant middleware (blog resolution by domain/subdomain)
- ✅ Public blog routes (index, post show, tags, feeds)
- ✅ Markdown rendering with mermaid diagram support
- ✅ SEO (sitemap.xml, robots.txt, RSS/Atom feeds)
- ✅ Authentication (login/logout, session management)
- ✅ Dashboard layout and navigation
- ✅ Dashboard home page (post list with pagination)
- ✅ Pagination for blog index and tag pages

### In Progress

- 🚧 Post edit/create forms
- 🚧 Rich text editor integration
- 🚧 Autosave system
- 🚧 Tag management
- 🚧 Blog settings page
- 🚧 User settings and password change

### Not Started

- ❌ Image uploads and storage
- ❌ Custom domains management
- ❌ API endpoints
- ❌ Email notifications
- ❌ Analytics
- ❌ Multiple blog support in UI
- ❌ Themes/customization

## Key Differences from Rails

### Authentication

- Rails uses Devise, Go uses custom session-based auth
- Both use bcrypt for passwords (compatible)
- Sessions stored in cookies (gorilla/sessions)
- User verification works with existing Rails user accounts

### Routing

- Rails: Conventional routes with resource helpers
- Go: Explicit route definitions in `cmd/server/main.go`
- Blog resolution happens via middleware, not routing

### Templates

- Rails: ERB with Ruby code
- Go: Go templates with limited logic
- Both use DaisyUI for styling
- Icons rendered differently (embedded vs asset pipeline)

### Markdown Processing

- Rails: Uses ruby libraries (not documented in codebase notes)
- Go: Uses goldmark with syntax highlighting
- Both support mermaid diagrams
- Frontmatter parsing handled by custom service

## Testing

**Status**: No tests yet for Go code.

**TODO**: 
- Add unit tests for repositories
- Add handler tests
- Add integration tests
- Match Rails test coverage

## Deployment

**Not yet configured**. The Rails app uses Docker on Fly.io. The Go version will need:

- Dockerfile
- Environment variable configuration
- Database connection pooling tuning
- Static asset serving strategy

## Common Issues

### CSS/JS not loading

**Error**: Styles not applying or Alpine.js not working.

**Solution**: Frontend assets haven't been built. Run:
```bash
cd go
npm install
npm run build
```

### Icons not building

See "Icons Generation" section above. You need to generate icons after cloning.

### Database connection fails

Ensure `DATABASE_URL` points to the Rails database and the format is:
```
postgres://username:password@host:port/database_name
```

### Templates not found

Template paths are relative to where you run the server. Run from the `go/` directory:
```bash
cd go
./server
```

### Port already in use

Rails runs on 3000, Go defaults to 3001. Change with `PORT` environment variable.

### Tailwind classes not applying

If you add new Tailwind classes and they don't appear:
1. Make sure Vite dev server is running (`npm run dev`)
2. Check that `tailwind.config.js` includes your template path
3. Rebuild with `npm run build`

## Contributing

When adding features:

1. Check Rails implementation first (app/controllers, app/views)
2. Match UI exactly using DaisyUI classes
3. Use existing patterns (repository layer, template functions)
4. Reuse the same database tables
5. Add any new icons to the generator
6. Update this CLAUDE.md file with progress

## Questions?

Check the main CLAUDE.md in the repository root for overall project conventions (spelling, code style, etc.).
