# Willow Camp CLI

A command-line interface for managing blog posts on a willow.camp.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'willow_camp_cli'
```

And then execute:

```bash
$ bundle install
```

Or install it yourself as:

```bash
$ gem install willow_camp_cli
```
## Usage

```
Usage: willow-camp COMMAND [options]

Commands:
  list                List all posts
  show                Show a single post by slug
  create              Create a new post from a Markdown file
  update              Update an existing post by slug
  delete              Delete a post by slug
  upload              Bulk upload posts from a directory
  download            Download a post to a Markdown file
  ghost-import        Import posts from a Ghost export file
  help                Show this help message

Options:
  -u, --url URL                  API URL (e.g., https://yourblog.example.com)
  -t, --token TOKEN              API Bearer Token
  -d, --directory DIRECTORY      Directory containing Markdown files (for upload)
  -f, --file FILE                Single Markdown file (for create/update)
  -s, --slug SLUG                Post slug (for show/update/delete/download)
  -o, --output FILE              Output file (for download)
  -g, --ghost-export FILE        Ghost export JSON file
      --output-dir DIRECTORY     Output directory for Ghost import (default: 'markdown')
      --dry-run                  Show what would be done without making actual changes
  -v, --verbose                  Show detailed output
  -h, --help                     Show this help message
```

## Examples

```sh
export WILLOW_CAMP_API_TOKEN=<your token>
```

### List all posts

```bash
willow-camp list
```

### Show a single post

```bash
willow-camp show -s my-post-slug
```

### Create a new post from a Markdown file

```bash
willow-camp create -f path/to/post.md
```

### Update an existing post

```bash
willow-camp update -s my-post-slug -f path/to/updated-post.md
```

### Delete a post

```bash
willow-camp delete -s my-post-slug
```

### Bulk upload posts from a directory

```bash
willow-camp upload -d path/to/markdown/files
```

### Download a post to a file

```bash
willow-camp download -s my-post-slug -o path/to/save.md
```

### Import posts from a Ghost export file

```bash
# Just convert to Markdown files
willow-camp ghost-import --ghost-export path/to/ghost-export.json --output-dir path/to/output

# Convert and upload in one step
willow-camp ghost-import -g path/to/ghost-export.json --output-dir path/to/output
```

## Environment Variables

You can set default API URL and token using environment variables:

```bash
export WILLOW_API_URL="https://yourblog.example.com"
export WILLOW_API_TOKEN="your-api-token"
```

If these environment variables are set, you don't need to provide the `-u` and `-t` options.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/yourusername/willow_camp.
