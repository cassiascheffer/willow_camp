require "test_helper"
require "stringio"
require "fileutils"
require "tempfile"
require "json"

module WillowCampCLI
  class CodeFenceTest < Minitest::Test
    def setup
      @token = "test-token-123"
      @base_options = {
        token: @token,
        directory: ".",
        dry_run: true, # Use dry run to avoid API calls
        verbose: false
      }

      # Capture stdout for testing output
      @original_stdout = $stdout
      $stdout = StringIO.new

      # Create temp directory for test files
      @temp_dir = File.join(Dir.tmpdir, "willow_camp_cli_code_fence_test_#{Time.now.to_i}")
      FileUtils.mkdir_p(@temp_dir)
    end

    def teardown
      # Restore stdout
      $stdout = @original_stdout

      # Remove test files
      FileUtils.rm_rf(@temp_dir) if Dir.exist?(@temp_dir)
    end

    def test_bash_code_fence_conversion
      html_content = <<~HTML
        <p>I work in a lot of Rails projects and one of my pet peeves is how long it takes to boot up Rails if all you need to do is view the generated routes with <code>rails routes</code>.</p>
        <p>A long while back I found/copied/modified this bash function from<a href="https://github.com/tlehman/bin/blob/master/fastroutes" rel="noreferrer"> tlehman, on GitHub</a>.</p>
        <p>What does it do? It stores the routes in a text file when you run the command. The file is named with an md5 checksum based on the contents of the routes file. If the file changes, the function will regenerate the routes. You can also force it to regenerate the file with the <code>-r</code> option.</p>
        <p>I'm no bash expert, so I'm sure there's a better way of doing this, but it works for me.</p>
        <pre><code class="language-bash">function fast-rails-routes() {
        	if [ ! -f config/routes.rb ]; then
        		echo "Not in root of Rails app"
        		exit 1
        	fi

        	cached_routes_filename="tmp/cached_routes_$(md5 -q config/routes.rb).txt"

        	function cache_routes {
        		echo "Generating new cache..."
        		rails routes &gt;$cached_routes_filename
        	}

        	function clear_cache {
        		for old_file in $(ls tmp/cache_routes*.txt); do
        			rm $old_file
        		done
        	}

        	function show_cache {
        		cat $cached_routes_filename
        	}

        	function show_current_filename {
        		echo $cached_routes_filename
        	}

        	if [[ "$1" == "-f" ]]; then
        		show_current_filename
        	elif [[ "$1" == "-r" ]]; then
        		rm $cached_routes_filename
        		cache_routes
        		show_cache
        	elif [[ "$1" == "-h" ]]; then
        		echo "Print all routes"
        		echo "$ fast_rails_routes"
        		echo
        		echo "Clear the cache and print all routes"
        		echo "$ fast_rails_routes -r"
        		echo
        		echo "Print out the cache file name"
        		echo "$ fast_rails_routes -f"
        	else
        		main
        	fi
        }</code></pre>
      HTML

      ghost_export_file = create_ghost_export_with_html(html_content, "bash-function-post")
      output_dir = File.join(@temp_dir, "output")

      cli = CLI.new(@base_options)
      cli.ghost_import(ghost_export_file, output_dir)

      # Check that the markdown file was created
      markdown_file = File.join(output_dir, "bash-function-post.md")
      assert File.exist?(markdown_file), "Markdown file should be created"

      content = File.read(markdown_file)

      # Check that code fence is properly formatted with bash language
      assert_match(/```bash\n/, content, "Should have bash code fence")
      assert_match(/function fast-rails-routes\(\) \{/, content, "Should contain function definition")
      assert_match(/\n```/, content, "Should have closing code fence")

      # Check that HTML entities are properly decoded
      assert_match(/rails routes >/, content, "Should decode &gt; entity")
      refute_match(/&gt;/, content, "Should not contain HTML entities")
    end

    def test_javascript_code_fence_conversion
      html_content = <<~HTML
        <p>Here's a JavaScript function example:</p>
        <pre><code class="language-javascript">function calculateSum(a, b) {
          if (typeof a !== 'number' || typeof b !== 'number') {
            throw new Error('Both arguments must be numbers');
          }

          return a + b;
        }

        // Usage example
        const result = calculateSum(5, 10);
        console.log(`The sum is: ${result}`);
        </code></pre>
        <p>This function adds two numbers together.</p>
      HTML

      ghost_export_file = create_ghost_export_with_html(html_content, "javascript-example")
      output_dir = File.join(@temp_dir, "output")

      cli = CLI.new(@base_options)
      cli.ghost_import(ghost_export_file, output_dir)

      markdown_file = File.join(output_dir, "javascript-example.md")
      content = File.read(markdown_file)

      # Check JavaScript code fence
      assert_match(/```javascript\n/, content, "Should have javascript code fence")
      assert_match(/function calculateSum\(a, b\)/, content, "Should contain function definition")
      assert_match(/console\.log/, content, "Should contain console.log statement")
      assert_match(/\n```/, content, "Should have closing code fence")
    end

    def test_python_code_fence_conversion
      html_content = <<~HTML
        <p>Here's a Python class example:</p>
        <pre><code class="language-python">class Calculator:
            def __init__(self):
                self.history = []

            def add(self, a, b):
                result = a + b
                self.history.append(f"{a} + {b} = {result}")
                return result

            def get_history(self):
                return self.history

        # Example usage
        calc = Calculator()
        print(calc.add(10, 5))
        </code></pre>
      HTML

      ghost_export_file = create_ghost_export_with_html(html_content, "python-example")
      output_dir = File.join(@temp_dir, "output")

      cli = CLI.new(@base_options)
      cli.ghost_import(ghost_export_file, output_dir)

      markdown_file = File.join(output_dir, "python-example.md")
      content = File.read(markdown_file)

      # Check Python code fence
      assert_match(/```python\n/, content, "Should have python code fence")
      assert_match(/class Calculator:/, content, "Should contain class definition")
      assert_match(/def __init__\(self\):/, content, "Should contain __init__ method")
      assert_match(/\n```/, content, "Should have closing code fence")
    end

    def test_code_fence_without_language_class
      html_content = <<~HTML
        <p>Here's code without a language specified:</p>
        <pre><code>const greeting = "Hello, World!";
        console.log(greeting);

        function sayHello(name) {
          return `Hello, ${name}!`;
        }
        </code></pre>
      HTML

      ghost_export_file = create_ghost_export_with_html(html_content, "no-language-example")
      output_dir = File.join(@temp_dir, "output")

      cli = CLI.new(@base_options)
      cli.ghost_import(ghost_export_file, output_dir)

      markdown_file = File.join(output_dir, "no-language-example.md")
      content = File.read(markdown_file)

      # Check that code fence is created without language identifier
      assert_match(/```\n/, content, "Should have code fence without language")
      assert_match(/const greeting = "Hello, World!";/, content, "Should contain code content")
      assert_match(/\n```/, content, "Should have closing code fence")
    end

    def test_multiple_code_fences_in_same_post
      html_content = <<~HTML
        <p>First, here's some Ruby code:</p>
        <pre><code class="language-ruby">class User
          attr_accessor :name, :email

          def initialize(name, email)
            @name = name
            @email = email
          end
        end
        </code></pre>

        <p>And here's some SQL:</p>
        <pre><code class="language-sql">SELECT u.name, u.email, COUNT(p.id) as post_count
        FROM users u
        LEFT JOIN posts p ON u.id = p.user_id
        WHERE u.active = true
        GROUP BY u.id, u.name, u.email
        ORDER BY post_count DESC;
        </code></pre>

        <p>Finally, some shell commands:</p>
        <pre><code class="language-shell">#!/bin/bash

        # Create database backup
        pg_dump myapp_production > backup_$(date +%Y%m%d).sql

        # Upload to S3
        aws s3 cp backup_$(date +%Y%m%d).sql s3://my-backups/
        </code></pre>
      HTML

      ghost_export_file = create_ghost_export_with_html(html_content, "multiple-code-blocks")
      output_dir = File.join(@temp_dir, "output")

      cli = CLI.new(@base_options)
      cli.ghost_import(ghost_export_file, output_dir)

      markdown_file = File.join(output_dir, "multiple-code-blocks.md")
      content = File.read(markdown_file)

      # Check all three code fences are present with correct languages
      assert_match(/```ruby\n/, content, "Should have ruby code fence")
      assert_match(/class User/, content, "Should contain Ruby class")

      assert_match(/```sql\n/, content, "Should have sql code fence")
      assert_match(/SELECT u\.name/, content, "Should contain SQL query")

      assert_match(/```shell\n/, content, "Should have shell code fence")
      assert_match(/pg_dump myapp_production/, content, "Should contain shell command")

      # Count the number of code fence pairs
      opening_fences = content.scan(/^```\w+\n/).length
      closing_fences = content.scan(/^```\n/).length
      assert_equal 3, opening_fences, "Should have 3 opening code fences"
      assert_equal 3, closing_fences, "Should have 3 closing code fences"
    end

    def test_inline_code_preservation
      html_content = <<~HTML
        <p>Use the <code>rails routes</code> command to see all routes.</p>
        <p>You can also run <code>rails console</code> or <code>rails server</code>.</p>
        <p>For debugging, try <code>binding.pry</code> in your code.</p>

        <p>Here's a longer code block:</p>
        <pre><code class="language-ruby">puts "Hello, World!"
        </code></pre>
      HTML

      ghost_export_file = create_ghost_export_with_html(html_content, "inline-code-example")
      output_dir = File.join(@temp_dir, "output")

      cli = CLI.new(@base_options)
      cli.ghost_import(ghost_export_file, output_dir)

      markdown_file = File.join(output_dir, "inline-code-example.md")
      content = File.read(markdown_file)

      # Check inline code preservation
      assert_match(/`rails routes`/, content, "Should preserve inline code")
      assert_match(/`rails console`/, content, "Should preserve inline code")
      assert_match(/`rails server`/, content, "Should preserve inline code")
      assert_match(/`binding.pry`/, content, "Should preserve inline code")

      # Check code block
      assert_match(/```ruby\n/, content, "Should have ruby code fence")
      assert_match(/puts "Hello, World!"/, content, "Should contain Ruby code")
    end

    def test_code_fence_with_special_characters
      html_content = <<~HTML
        <p>Here's code with special characters and HTML entities:</p>
        <pre><code class="language-xml">&lt;?xml version="1.0" encoding="UTF-8"?&gt;
        &lt;root&gt;
          &lt;item id="1"&gt;
            &lt;name&gt;Sample &amp;amp; Test&lt;/name&gt;
            &lt;value&gt;100 &lt; 200 &amp;&amp; 50 &gt; 25&lt;/value&gt;
          &lt;/item&gt;
        &lt;/root&gt;
        </code></pre>
      HTML

      ghost_export_file = create_ghost_export_with_html(html_content, "special-chars-example")
      output_dir = File.join(@temp_dir, "output")

      cli = CLI.new(@base_options)
      cli.ghost_import(ghost_export_file, output_dir)

      markdown_file = File.join(output_dir, "special-chars-example.md")
      content = File.read(markdown_file)

      # Check XML code fence
      assert_match(/```xml\n/, content, "Should have xml code fence")

      # Check that HTML entities are properly decoded
      assert_match(/<\?xml version="1\.0"/, content, "Should decode XML declaration")
      assert_match(/<root>/, content, "Should decode root tag")
      assert_match(/Sample & Test/, content, "Should decode &amp; entity")
      assert_match(/100 < 200/, content, "Should decode &lt; entity")
      assert_match(/50 > 25/, content, "Should decode &gt; entity")

      # Ensure no HTML entities remain
      refute_match(/&lt;/, content, "Should not contain &lt; entities")
      refute_match(/&gt;/, content, "Should not contain &gt; entities")
      refute_match(/&amp;/, content, "Should not contain &amp; entities")
    end

    def test_nested_code_and_pre_tags
      html_content = <<~HTML
        <p>Sometimes you might have nested scenarios:</p>
        <pre><code class="language-html">&lt;pre&gt;&lt;code&gt;
        console.log("This is nested code");
        &lt;/code&gt;&lt;/pre&gt;
        </code></pre>
      HTML

      ghost_export_file = create_ghost_export_with_html(html_content, "nested-code-example")
      output_dir = File.join(@temp_dir, "output")

      cli = CLI.new(@base_options)
      cli.ghost_import(ghost_export_file, output_dir)

      markdown_file = File.join(output_dir, "nested-code-example.md")
      content = File.read(markdown_file)

      # Check HTML code fence
      assert_match(/```html\n/, content, "Should have html code fence")
      assert_match(/<pre><code>/, content, "Should contain decoded nested tags")
      assert_match(/console\.log/, content, "Should contain JavaScript code")
    end

    private

    def create_ghost_export_with_html(html_content, slug)
      ghost_export_file = File.join(@temp_dir, "#{slug}-export.json")

      ghost_data = {
        "db" => [
          {
            "data" => {
              "posts" => [
                {
                  "id" => "1",
                  "title" => "Code Fence Test Post",
                  "slug" => slug,
                  "status" => "published",
                  "published_at" => "2025-01-01T12:00:00.000Z",
                  "html" => html_content,
                  "custom_excerpt" => "Test post for code fence conversion"
                }
              ],
              "tags" => [],
              "posts_tags" => []
            }
          }
        ]
      }

      File.write(ghost_export_file, ghost_data.to_json)
      ghost_export_file
    end
  end
end
