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

The application is organized by three main areas (blog, dashboard, shared) with shared infrastructure at the top level:

```
go/
├── cmd/server/           # Application entry point
├── internal/
│   ├── blog/            # Public blog pages area
│   │   ├── handlers/    # Blog handlers (posts, tags, feeds, SEO)
│   │   ├── middleware/  # Blog resolver middleware
│   │   └── templates/   # Blog page templates
│   ├── dashboard/       # Dashboard/admin area
│   │   ├── handlers/    # Dashboard handlers (posts, settings, security, tags)
│   │   └── templates/   # Dashboard templates
│   ├── shared/          # Shared public pages (home, auth)
│   │   ├── handlers/    # Auth and home handlers
│   │   └── templates/   # Simple layout for auth
│   ├── auth/            # Authentication service (infrastructure)
│   ├── flash/           # Flash messages (infrastructure)
│   ├── helpers/         # Template helpers (infrastructure)
│   ├── icons/           # Heroicon SVG files (see below)
│   ├── logging/         # Structured logging (infrastructure)
│   ├── markdown/        # Markdown rendering (infrastructure)
│   ├── models/          # Data models (infrastructure)
│   └── repository/      # Database access layer (infrastructure)
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
# Development build with watch mode (rebuilds on file changes)
npm run dev

# Production build (one-time build)
npm run build
```

**Important**:
- The build outputs to `static/dist/` which is served by the Go server at `/static/dist/`
- This is **server-side rendering** - the Go server serves the built CSS/JS files
- In dev mode, `npm run dev` runs `vite build --watch` which writes files to disk (not an in-memory dev server)
- You must build assets before running the Go server, or styles won't load

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

### Icons

The app uses [Heroicons](https://heroicons.com) from the official Tailwind Labs repository. Icons are fetched as SVG files and rendered in templates using helper functions.

#### How Icons Work

1. **Source**: Official heroicons GitHub repository: https://github.com/tailwindlabs/heroicons
2. **Storage**: SVG files committed to `internal/icons/`
3. **Fetching**: `scripts/fetch-heroicons.sh` downloads icons from GitHub
4. **Rendering**: `helpers.Icon()` function loads SVGs and applies CSS classes

#### Fetching Icons

The icons are committed to the repository, so they're available immediately after cloning. You only need to run the fetch script when adding new icons or updating existing ones:

```bash
cd go
./scripts/fetch-heroicons.sh
```

This downloads SVG files from the heroicons repository and saves them to `internal/icons/`.

**Run this script when**:
- Adding new icons to the script
- Updating to new versions of heroicons

#### Adding New Icons

Edit `scripts/fetch-heroicons.sh` and add the icon path to the `icons` array:

```bash
declare -a icons=(
    # Add your icon here
    "24/outline/your-icon-name"  # 24px outline icon
    "20/solid/your-icon-name"    # 20px solid icon (mini)
    "16/solid/your-icon-name"    # 16px solid icon (micro)
)
```

Then re-run the script:

```bash
./scripts/fetch-heroicons.sh
```

#### Using Icons in Templates

Templates use the `heroicon` and `heroiconMini` functions to render icons with custom classes:

```html
{{heroicon "check" "h-5 w-5"}}          <!-- 24px outline icon -->
{{heroiconMini "plus" "h-4 w-4"}}       <!-- 20px solid icon -->
```

The functions:
- Load the SVG file from `internal/icons/`
- Remove hardcoded attributes (width, height, stroke color)
- Add the provided CSS classes
- Return template.HTML for safe rendering

#### Icon Directory Structure

```
internal/icons/
├── 24/
│   ├── outline/         # 24px outline icons
│   │   ├── check.svg
│   │   ├── cog-6-tooth.svg
│   │   └── ...
│   └── solid/           # 24px solid icons
│       └── ...
├── 20/
│   └── solid/           # 20px solid icons (mini)
│       ├── check.svg
│       ├── plus.svg
│       └── ...
└── 16/
    └── solid/           # 16px solid icons (micro)
        └── ...
```

**Why commit icons to the repository?**
- Simple deployment (no build-time fetching required)
- Small package size (~20KB for all icons)
- Guarantees availability (no external dependency at deploy time)
- Easy to update via `scripts/fetch-heroicons.sh`
- No dependencies in go.mod for icon handling

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

The Go app uses **Vite** for frontend builds with **server-side rendering**:

**Development workflow**:
1. Run `npm run dev` in one terminal (builds and watches for changes)
2. Run Go server in another terminal
3. Edit CSS in `src/main.css` or JS in `src/main.js`
4. Vite rebuilds automatically to `static/dist/`
5. Refresh browser to see changes

**How it works**:
- `src/main.js` imports `src/main.css` and Alpine.js
- `src/main.css` imports accessibility.css and includes Tailwind directives
- Vite bundles everything to `static/dist/main.css` and `static/dist/main.js`
- Go server serves these files at `/static/dist/` (NOT a proxy to Vite dev server)
- Templates reference the built assets: `<link href="/static/dist/main.css">`
- Tailwind scans `internal/templates/**/*.html` for classes to include

**Key difference from typical Vite setup**:
- We use `vite build --watch` instead of `vite dev` for development
- This writes files to disk so the Go server can serve them
- It's server-side rendering, not a client-side SPA

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
- do not try boot the app. I'll do it
- javascript should always be in js files. don't add js directly in the html
- I use ./run.sh to run the server. assets get rebuilt by vite
- all work in the go app should be committed to go-development and pushed to github
- Always use context7 when I need code generation, setup or configuration steps, or
library/API documentation. This means you should automatically use the Context7 MCP
tools to resolve library id and get library docs without me having to explicitly ask.