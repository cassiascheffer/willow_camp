# Willow Camp

Willow Camp is a minimalist blogging platform built with Ruby on Rails and styled with a customizable theme system supporting Tokyo Night and Solarized color schemes.

## Features

- Clean, responsive blog post interface
- Multi-theme system with Tokyo Night and Solarized themes
- Dark/light mode support
- Markdown post content
- Pagination
- SEO-friendly URLs

## Development Setup

### Prerequisites

- Ruby 3.2.0+
- Node.js 18+
- PostgreSQL 14+
- Yarn or npm

### Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/willow_camp.git
cd willow_camp
```

2. Install dependencies:
```bash
bundle install
```

3. Setup database:
```bash
rails db:setup
```

4. Start development servers:
```bash
# In one terminal:
bin/dev
```

5. Visit http://localhost:3000

### Theme Customization

The theme system is configured in `app/assets/tailwind/application.css`. To switch between themes:

1. Change the `--theme` CSS variable to either `"tokyo"` or `"solarized"`
2. Set `data-theme` attribute on the root element to match

### Testing

Run the test suite with:

```bash
rails test
```

## Deployment

The application is designed to be deployed to any standard Rails hosting platform like Heroku, Fly.io, or Railway.

Standard deployment commands:

```bash
rails assets:precompile
rails db:migrate
```
