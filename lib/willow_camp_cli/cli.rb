require "json"
require "uri"
require "net/http"
require "optparse"
require "pathname"
require "colorize"
require "fileutils"
require "reverse_markdown"

module WillowCampCLI
  class CLI
    API_URL = "https://willow.camp/"
    attr_reader :token, :verbose

    def initialize(options)
      @token = options[:token]
      @directory = options[:directory]
      @dry_run = options[:dry_run]
      @verbose = options[:verbose]
      @slug = options[:slug]
    end

    # List all posts
    def list_posts
      puts "📋 Listing all posts from #{API_URL}...".blue

      response = api_request(:get, "/api/posts")
      if response
        posts = JSON.parse(response.body)["posts"]
        if posts.empty?
          puts "No posts found".yellow
        else
          puts "\nFound #{posts.size} post(s):".green
          posts.each do |post|
            puts "- [#{post["id"]}] #{post["slug"]}".cyan
          end
        end
      end
    end

    # Show a single post by slug
    def show_post
      return puts "Error: Slug is required".red unless @slug

      puts "🔍 Fetching post with slug: #{@slug}...".blue

      response = api_request(:get, "/api/posts/#{@slug}")
      if response
        post = JSON.parse(response.body)["post"]
        puts "\nPost details:".green
        puts "ID: #{post["id"]}".cyan
        puts "Slug: #{post["slug"]}".cyan
        puts "Title: #{post.dig("title")}".cyan
        puts "Published: #{post["published"] || false}".cyan
        puts "Published at: #{post["published_at"] || "Not published"}".cyan
        puts "Tags: #{(post["tag_list"] || []).join(", ")}".cyan

        if @verbose
          puts "\nContent:".cyan
          puts "-" * 50
          puts post["markdown"]
          puts "-" * 50
        end
      end
    end

    # Update a post by slug
    def update_post(content)
      return puts "Error: Slug and content are required".red unless @slug && content

      puts "🔄 Updating post with slug: #{@slug}...".blue

      if @dry_run
        puts "  DRY RUN: Would update post #{@slug}".yellow
        puts "  Content preview: #{content[0..100]}...".yellow if @verbose
        return
      end

      response = api_request(:patch, "/api/posts/#{@slug}", {post: {markdown: content}})
      if response
        post = JSON.parse(response.body)["post"]
        puts "✅ Successfully updated post: #{post["title"]} (#{post["slug"]})".green
      end
    end

    # Delete a post by slug
    def delete_post
      return puts "Error: Slug is required".red unless @slug

      puts "🗑️ Deleting post with slug: #{@slug}...".blue

      if @dry_run
        puts "  DRY RUN: Would delete post #{@slug}".yellow
        return
      end

      response = api_request(:delete, "/api/posts/#{@slug}")
      if response && response.code.to_i == 204
        puts "✅ Successfully deleted post: #{@slug}".green
      end
    end

    # Upload a single Markdown file
    def upload_file(file_path)
      puts "📤 Uploading #{file_path}...".blue
      content = File.read(file_path)

      if @dry_run
        puts "  DRY RUN: Would upload #{file_path}".yellow
        puts "  Content preview: #{content[0..100]}...".yellow if @verbose
        return
      end

      response = api_request(:post, "/api/posts", {post: {markdown: content}})
      if response
        post = JSON.parse(response.body)["post"]
        puts "✅ Successfully uploaded: #{file_path}".green
        puts "📌 Created post '#{post["title"]}' with slug: #{post["slug"]}".green
      end
    end

    # Upload all Markdown files from a directory
    def upload_all
      puts "🔍 Looking for Markdown files in #{@directory}...".blue

      files = find_markdown_files
      if files.empty?
        puts "❌ No Markdown files found in #{@directory}".red
        return
      end

      puts "📝 Found #{files.size} Markdown file(s)".blue

      files.each_with_index do |file, index|
        puts "\n[#{index + 1}/#{files.size}] Processing #{file}".cyan
        upload_file(file)
      end

      puts "\n✅ Operation complete!".green
    end

    # Download a post to a file
    def download_post(output_path)
      return puts "Error: Slug is required".red unless @slug

      puts "📥 Downloading post with slug: #{@slug}...".blue

      response = api_request(:get, "/api/posts/#{@slug}")
      if response
        post = JSON.parse(response.body)["post"]

        # Use provided output path or generate one based on slug
        output_path ||= "#{@slug}.md"

        File.write(output_path, post["markdown"])
        puts "✅ Successfully downloaded post to #{output_path}".green
      end
    end

    # Import posts from a Ghost export file
    def ghost_import(ghost_export_file, output_dir = "markdown")
      return puts "Error: Ghost export file is required".red unless ghost_export_file
      return puts "Error: Ghost export file not found: #{ghost_export_file}".red unless File.exist?(ghost_export_file)

      puts "🔍 Processing Ghost export file: #{ghost_export_file}...".blue

      begin
        # Create output directory if it doesn't exist
        FileUtils.mkdir_p(output_dir) unless Dir.exist?(output_dir)

        # Parse JSON export file
        ghost_data = JSON.parse(File.read(ghost_export_file))

        posts = ghost_data["db"][0]["data"]["posts"].select { |post| post["status"] == "published" }

        if posts.empty?
          puts "❌ No published posts found in the Ghost export".red
          return
        end

        puts "Found #{posts.size} published posts".green

        # Process each post
        processed_count = 0
        posts.each do |post|
          title = post["title"]
          slug = post["slug"]
          published = post["status"] == "published" ? !post["published_at"].nil? : nil
          published_at = post["published_at"]&.split("T")&.first

          puts "\n[#{processed_count + 1}/#{posts.size}] Processing '#{title}' (#{slug})".cyan

          # Get content from the most appropriate source
          # First try html, then markdown (for test compatibility), then lexical, then plaintext
          content = nil

          if post["html"] && !post["html"].empty?
            # Convert HTML to Markdown
            html_content = post["html"]
            content = ReverseMarkdown.convert(html_content, github_flavored: true, code_block_style: :fenced)
            # Preserve language attributes from code blocks
            content = preserve_code_fence_languages(html_content, content)
            # Decode HTML entities
            content = decode_html_entities(content)
            # Clean up code formatting issues
            content = clean_code_formatting(content)
            # Clean up malformed links from Ghost cards
            content = clean_malformed_links(content)
            source = "html converted to markdown"
            puts "  Note: Converting HTML content to markdown".yellow if @verbose
          elsif post["plaintext"] && !post["plaintext"].empty?
            content = post["plaintext"]
            source = "plaintext"
            puts "  Note: Using plaintext content (HTML/lexical not available)".yellow if @verbose
          else
            puts "  Warning: No content found for post '#{title}'".yellow
            next
          end

          # Replace Ghost URL placeholders if present
          content = content.gsub(/__GHOST_URL__/, "")

          # Get tags for this post
          tags = []
          if ghost_data["db"][0]["data"]["posts_tags"]
            post_tags = ghost_data["db"][0]["data"]["posts_tags"].select { |pt| pt["post_id"] == post["id"] }

            post_tags.each do |pt|
              tag = ghost_data["db"][0]["data"]["tags"].find { |t| t["id"] == pt["tag_id"] }
              tags << tag["name"] if tag
            end
          end

          # Get feature image
          feature_image = post["feature_image"]
          feature_image&.gsub!(/__GHOST_URL__/, "")

          # Create markdown file with proper frontmatter
          filename = File.join(output_dir, "#{slug}.md")

          File.open(filename, "w") do |file|
            file.puts "---"
            file.puts "title: \"#{title}\""
            file.puts "published_at: #{published_at}" if published_at
            file.puts "slug: #{slug}"
            file.puts "published: #{published}" if published

            # Add meta description if available
            if post["custom_excerpt"] && !post["custom_excerpt"].empty?
              file.puts "meta_description: \"#{post['custom_excerpt']}\""
            end

            # Add tags if available
            unless tags.empty?
              file.puts "tags:"
              tags.each do |tag|
                file.puts "  - #{tag}"
              end
            end

            file.puts "---"
            file.puts
            file.puts content
          end

          puts "  ✅ Created: #{filename} (from #{source})".green
          processed_count += 1

          # Upload the post if requested
          if @token && !@dry_run
            upload_file(filename)
          elsif @dry_run
            puts "  DRY RUN: Would upload #{filename}".yellow
          end
        end

        puts "\n✅ Conversion complete! #{processed_count} markdown files created in #{output_dir}/".green

      rescue JSON::ParserError => e
        puts "❌ Error parsing Ghost export JSON: #{e.message}".red
      rescue => e
        puts "❌ Error processing Ghost export: #{e.message}".red
        puts e.backtrace.join("\n") if @verbose
      end
    end

    def self.run(args, testing = false)
      command = args.shift
      commands = %w[list show create update delete upload download ghost-import help]

      unless commands.include?(command)
        puts "Unknown command: #{command}".red
        puts "Available commands: #{commands.join(", ")}"
        return false if testing
        exit(1)
      end

      # Parse command-line options
      options = {
        token: ENV["WILLOW_CAMP_API_TOKEN"],
        directory: ".",
        file: nil,
        slug: nil,
        output: nil,
        ghost_export: nil,
        output_dir: "markdown",
        dry_run: false,
        verbose: false
      }

      opt_parser = OptionParser.new do |opts|
        opts.banner = "Usage: willow-camp COMMAND [options]"
        opts.separator ""
        opts.separator "Commands:"
        opts.separator "  list                List all posts"
        opts.separator "  show                Show a single post by slug"
        opts.separator "  create              Create a new post from a Markdown file"
        opts.separator "  update              Update an existing post by slug"
        opts.separator "  delete              Delete a post by slug"
        opts.separator "  upload              Bulk upload posts from a directory"
        opts.separator "  download            Download a post to a Markdown file"
        opts.separator "  ghost-import        Import posts from a Ghost export file"
        opts.separator "  help                Show this help message"
        opts.separator ""
        opts.separator "Options:"




        opts.on("-t", "--token TOKEN", "API Bearer Token") do |token|
          options[:token] = token
        end

        opts.on("-d", "--directory DIRECTORY", "Directory containing Markdown files (for upload)") do |dir|
          options[:directory] = dir
        end

        opts.on("-f", "--file FILE", "Single Markdown file (for create/update)") do |file|
          options[:file] = file
        end

        opts.on("-s", "--slug SLUG", "Post slug (for show/update/delete/download)") do |slug|
          options[:slug] = slug
        end

        opts.on("-o", "--output FILE", "Output file (for download)") do |file|
          options[:output] = file
        end

        opts.on("-g", "--ghost-export FILE", "Ghost export JSON file") do |file|
          options[:ghost_export] = file
        end

        opts.on("--output-dir DIRECTORY", "Output directory for Ghost import (default: 'markdown')") do |dir|
          options[:output_dir] = dir
        end

        opts.on("--dry-run", "Show what would be done without making actual changes") do
          options[:dry_run] = true
        end

        opts.on("-v", "--verbose", "Show detailed output") do
          options[:verbose] = true
        end

        opts.on("-h", "--help", "Show this help message") do
          puts opts
          exit
        end
      end

      # Special case for help command
      if command == "help"
        puts opt_parser
        exit
      end

      # Parse the command-line arguments
      opt_parser.parse!(args)

      # Validate required options for each command
      case command
      when "list"
        # No specific validation needed
      when "show", "delete", "download"
        if !options[:slug]
          puts "Error: Slug is required for #{command} command (use --slug)".red
          exit 1
        end
      when "create"
        if !options[:file]
          puts "Error: File path is required for create command (use --file)".red
          exit 1
        end
      when "update"
        if !options[:slug] || !options[:file]
          puts "Error: Both slug and file are required for update command (use --slug and --file)".red
          exit 1
        end
      when "upload"
        # No specific validation needed beyond the common ones
      when "ghost-import"
        if !options[:ghost_export]
          puts "Error: Ghost export file is required for ghost-import command (use --ghost-export)".red
          exit 1
        end
      end

      # Common validation for token (except for dry runs and ghost-import when not uploading)
      unless options[:token] || options[:dry_run] || (command == "ghost-import" && !options[:token])
        puts "Error: API token is required (unless using --dry-run)".red
        puts "Try 'willow-camp help' for more information"
        exit 1
      end

      # Create client and execute command
      begin
        client = new(options)

        case command
        when "list"
          client.list_posts
        when "show"
          client.show_post
        when "create"
          content = File.read(options[:file])
          client.upload_file(options[:file])
        when "update"
          content = File.read(options[:file])
          client.update_post(content)
        when "delete"
          client.delete_post
        when "upload"
          client.upload_all
        when "download"
          client.download_post(options[:output])
        when "ghost-import"
          client.ghost_import(options[:ghost_export], options[:output_dir])
        end
      rescue => e
        puts "Error: #{e.message}".red
        exit 1
      end
    end

    private

    def decode_html_entities(content)
      # Decode common HTML entities
      content.gsub!(/&amp;/, '&')
      content.gsub!(/&lt;/, '<')
      content.gsub!(/&gt;/, '>')
      content.gsub!(/&quot;/, '"')
      content.gsub!(/&#39;/, "'")
      content.gsub!(/&nbsp;/, ' ')
      content
    end

    def clean_code_formatting(content)
      # Fix common formatting issues in code blocks
      # Remove extra spaces before parentheses in function definitions
      content.gsub!(/def\s+(\w+)\s+\(/, 'def \1(')
      content
    end

    def preserve_code_fence_languages(html_content, markdown_content)
      # Extract language information from HTML code blocks
      languages = []
      html_content.scan(/<pre><code[^>]*class="language-([^"]+)"[^>]*>/i) do |match|
        languages << match[0]
      end

      return markdown_content if languages.empty?

      # Split content into lines and process
      lines = markdown_content.lines
      result_lines = []
      code_block_index = 0
      in_code_block = false

      i = 0
      while i < lines.length
        line = lines[i]

        # Check if this line is a code fence
        if line.strip == '```'
          if !in_code_block
            # This is an opening code fence
            if code_block_index < languages.length
              result_lines << "```#{languages[code_block_index]}\n"
              code_block_index += 1
            else
              result_lines << line
            end
            in_code_block = true
          else
            # This is a closing code fence
            result_lines << line
            in_code_block = false
          end
        else
          result_lines << line
        end

        i += 1
      end

      result_lines.join
    end

    def clean_malformed_links(content)
      # Fix malformed links that span multiple lines with extra content
      # Pattern: [\n\nTITLE\n\nExtra content\n\n ![](image) more text](URL)
      # Should become: [TITLE](URL)
      content.gsub(/\[\s*\n\s*\n\s*([^\n]+).*?\]\((https?:\/\/[^\)]+)\)/m) do |match|
        title = $1.strip
        url = $2

        if title && !title.empty?
          "[#{title}](#{url})"
        else
          match # Keep original if we can't extract a clean title
        end
      end
    end

    def find_markdown_files
      Dir.glob(File.join(@directory, "**", "*.md"))
    end

    def api_request(method, endpoint, data = nil)
      uri = URI("#{API_URL}#{endpoint}")

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"

      case method
      when :get
        request = Net::HTTP::Get.new(uri)
      when :post
        request = Net::HTTP::Post.new(uri)
      when :patch
        request = Net::HTTP::Patch.new(uri)
      when :delete
        request = Net::HTTP::Delete.new(uri)
      else
        puts "❌ Unsupported HTTP method: #{method}".red
        return nil
      end

      request["Content-Type"] = "application/json"
      request["Authorization"] = "Bearer #{@token}" if @token
      request.body = data.to_json if data

      if @verbose
        puts "🔗 API Endpoint: #{uri} (#{method.to_s.upcase})".blue
        puts "📄 Request body: #{request.body}" if request.body && @verbose
      end

      begin
        response = http.request(request)

        case response.code.to_i
        when 200..299
          response
        else
          puts "❌ API request failed: HTTP #{response.code}".red
          puts "Error: #{response.body}".red
          nil
        end
      rescue => e
        puts "❌ Error making API request: #{e.message}".red
        nil
      end
    end
  end
end
