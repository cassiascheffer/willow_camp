# ⛺ [willow.camp](https://willow.camp)

A blogging platform built with Ruby on Rails. Supports subdomains, custom domains, multiple themes, and markdown posts.

## Features

- Blog post interface with pagination
- DaisyUI theme picker
- Markdown posts with YAML frontmatter
- API for post management. See [API documentation](docs/api.md).
- CLI for post management: [@cassiascheffer/willow_camp_cli](https://github.com/cassiascheffer/willow_camp_cli)

## Development Setup

### Prerequisites

- Ruby 3.2.0+
- Node.js 18+
- PostgreSQL 14+
- Yarn or npm

### Installation

1. Clone the repository:
```bash
git clone https://github.com/cassiascheffer/willow_camp.git
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
bin/dev
```

5. Visit http://localhost:3000

### Theme Configuration

Themes can be changed in the settings page. The application supports all DaisyUI themes.

### Testing

```bash
rails test
```


## Deployment

Deploy to any Rails hosting platform (Heroku, Fly.io, Railway).

```bash
rails assets:precompile
rails db:migrate
```

## License

**This license applies to the willow.camp software only, not to any content created using the software.**

[willow.camp](https://github.com/cassiascheffer/willow_camp) by [Cassia Scheffers(https://github.com/cassiascheffer) software is licensed under a [Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License](https://creativecommons.org/licenses/by-nc-sa/4.0/).

[![CC BY-NC-SA 4.0](https://licensebuttons.net/l/by-nc-sa/4.0/88x31.png)](https://creativecommons.org/licenses/by-nc-sa/4.0/)

**Note:** Content created by users of willow.camp (blog posts, images, etc.) remains the property of the respective content creators and is not covered by this license.
