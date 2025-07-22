require "test_helper"
require "stringio"
require "fileutils"
require "tempfile"
require "json"

module WillowCampCLI
  class GhostImportTest < Minitest::Test
    def setup
      @token = "test-token-123"
      @base_options = {
        token: @token,
        directory: ".",
        dry_run: false,
        verbose: false
      }

      # Capture stdout for testing output
      @original_stdout = $stdout
      $stdout = StringIO.new

      # Create temp directory for test files
      @temp_dir = File.join(Dir.tmpdir, "willow_camp_cli_test_#{Time.now.to_i}")
      FileUtils.mkdir_p(@temp_dir)

      # Create a sample Ghost export file
      @ghost_export_file = File.join(@temp_dir, "ghost-export.json")
      create_sample_ghost_export(@ghost_export_file)

      # Setup WebMock stubs
      WebMock.reset!
    end

    def teardown
      # Restore stdout
      $stdout = @original_stdout

      # Remove test files
      FileUtils.rm_rf(@temp_dir) if Dir.exist?(@temp_dir)
    end

    def test_ghost_import
      output_dir = File.join(@temp_dir, "output")

      # Stub the API requests for post uploads
      stub_request(:post, "#{CLI::API_URL}/api/posts")
        .with(headers: {"Authorization" => "Bearer #{@token}", "Content-Type" => "application/json"})
        .to_return(
          status: 200,
          body: '{"post":{"id":"123","title":"Test Post","slug":"test-post"}}',
          headers: {"Content-Type" => "application/json"}
        )

      cli = CLI.new(@base_options)
      cli.ghost_import(@ghost_export_file, output_dir)

      # Check that files were created
      assert Dir.exist?(output_dir), "Output directory should be created"

      # Check if markdown files were created
      markdown_files = Dir.glob(File.join(output_dir, "*.md"))
      assert_equal 2, markdown_files.size, "Should create markdown files for each post"

      # Check content of one of the files
      test_post_file = File.join(output_dir, "test-post.md")
      assert File.exist?(test_post_file), "test-post.md should exist"

      content = File.read(test_post_file)
      assert_match(/title: "Test Post"/, content)
      assert_match(/slug: test-post/, content)
      assert_match(/published: true/, content)
      assert_match(/tags:\n  - test\n  - ruby/, content)
      assert_match(/# Test Post Content/, content)

      # Check output messages
      output = $stdout.string
      assert_match(/Processing Ghost export file/, output)
      assert_match(/Found 2 published posts/, output)
      assert_match(/Created: #{test_post_file}/, output)
      assert_match(/Conversion complete! 2 markdown files created/, output)
    end

    def test_ghost_import_with_no_file
      cli = CLI.new(@base_options)
      cli.ghost_import(nil)

      output = $stdout.string
      assert_match(/Error: Ghost export file is required/, output)
    end

    def test_ghost_import_with_nonexistent_file
      cli = CLI.new(@base_options)
      cli.ghost_import("nonexistent-file.json")

      output = $stdout.string
      assert_match(/Error: Ghost export file not found/, output)
    end

    def test_ghost_import_with_empty_posts
      empty_export_file = File.join(@temp_dir, "empty-export.json")

      # Create an export file with no posts
      ghost_data = {
        "db" => [
          {
            "data" => {
              "posts" => []
            }
          }
        ]
      }

      File.write(empty_export_file, ghost_data.to_json)

      cli = CLI.new(@base_options)
      cli.ghost_import(empty_export_file, @temp_dir)

      output = $stdout.string
      assert_match(/No published posts found/, output)
    end

    def test_ghost_import_with_dry_run
      output_dir = File.join(@temp_dir, "output")

      cli = CLI.new(@base_options.merge(dry_run: true))
      cli.ghost_import(@ghost_export_file, output_dir)

      # Files should still be created in dry run mode
      assert Dir.exist?(output_dir), "Output directory should be created"

      # But upload should not be attempted
      output = $stdout.string
      assert_match(/DRY RUN: Would upload/, output)
    end

    def test_ghost_import_with_code_fences
      output_dir = File.join(@temp_dir, "output")

      # Create a more complex Ghost export with code fences
      ghost_export_file = File.join(@temp_dir, "code-fence-export.json")
      create_ghost_export_with_code_fences(ghost_export_file)

      # Stub the API request for post upload
      stub_request(:post, "#{CLI::API_URL}/api/posts")
        .with(headers: {"Authorization" => "Bearer #{@token}", "Content-Type" => "application/json"})
        .to_return(
          status: 200,
          body: '{"post":{"id":"123","title":"Code Example Post","slug":"code-example-post"}}',
          headers: {"Content-Type" => "application/json"}
        )

      cli = CLI.new(@base_options)
      cli.ghost_import(ghost_export_file, output_dir)

      # Check that the markdown file was created
      markdown_file = File.join(output_dir, "code-example-post.md")
      assert File.exist?(markdown_file), "Markdown file should be created"

      content = File.read(markdown_file)

      # Check that code fences are properly converted
      assert_match(/```ruby\n/, content, "Should have ruby code fence")
      assert_match(/```javascript\n/, content, "Should have javascript code fence")
      assert_match(/def hello_world/, content, "Should contain Ruby code")
      assert_match(/console\.log/, content, "Should contain JavaScript code")

      # Check that inline code is preserved
      assert_match(/`rails routes`/, content, "Should preserve inline code")

      # Ensure HTML entities are decoded in code blocks
      refute_match(/&gt;/, content, "Should not contain HTML entities")
      refute_match(/&lt;/, content, "Should not contain HTML entities")
    end

    def test_run_with_ghost_import_command
      mock_cli = Minitest::Mock.new
      mock_cli.expect :ghost_import, nil, [@ghost_export_file, "output"]

      CLI.stub :new, mock_cli do
        CLI.run(["ghost-import", "--ghost-export", @ghost_export_file, "--output-dir", "output"])
      end

      mock_cli.verify
    end

    private

    def create_ghost_export_with_code_fences(file_path)
      # Create a Ghost export with code fence examples
      ghost_data = {
        "db" => [
          {
            "data" => {
              "posts" => [
                {
                  "id" => "1",
                  "title" => "Code Example Post",
                  "slug" => "code-example-post",
                  "status" => "published",
                  "published_at" => "2025-01-01T12:00:00.000Z",
                  "html" => <<~'HTML',
                    <p>Here's how to use the <code>rails routes</code> command effectively.</p>

                    <p>First, let's look at a Ruby method:</p>
                    <pre><code class="language-ruby">def hello_world
                      puts "Hello, World!"
                      return "success"
                    end

                    # Call the method
                    result = hello_world
                    puts "Result: #{result}"</code></pre>

                    <p>And here's some JavaScript for comparison:</p>
                    <pre><code class="language-javascript">function helloWorld() {
                      console.log("Hello, World!");
                      return "success";
                    }

                    // Call the function
                    const result = helloWorld();
                    console.log(`Result: ${result}`);</code></pre>

                    <p>You can also use shell commands like <code>ls -la</code> and <code>grep -r "pattern" .</code></p>

                    <p>Here's a more complex example with HTML entities:</p>
                    <pre><code class="language-bash">if [ $count -gt 10 ]; then
                      echo "Count is greater than 10"
                      result="success"
                    fi

                    # Redirect output
                    echo "Done" &gt; output.txt</code></pre>
                  HTML
                  "custom_excerpt" => "Post demonstrating code fence conversion"
                }
              ],
              "tags" => [
                {
                  "id" => "1",
                  "name" => "code"
                },
                {
                  "id" => "2",
                  "name" => "tutorial"
                }
              ],
              "posts_tags" => [
                {
                  "post_id" => "1",
                  "tag_id" => "1"
                },
                {
                  "post_id" => "1",
                  "tag_id" => "2"
                }
              ]
            }
          }
        ]
      }

      File.write(file_path, ghost_data.to_json)
    end

    def create_sample_ghost_export(file_path)
      # Create a sample Ghost export file
      ghost_data = {
        "db" => [
          {
            "data" => {
              "posts" => [
                {
                  "id" => "1",
                  "title" => "Test Post",
                  "slug" => "test-post",
                  "status" => "published",
                  "published_at" => "2025-05-01T12:00:00.000Z",
                  "html" => "<h1>Test Post Content</h1><p>This is a test post.</p>",
                  "feature_image" => "__GHOST_URL__/content/images/test-image.jpg",
                  "custom_excerpt" => "This is a test excerpt"
                },
                {
                  "id" => "2",
                  "title" => "Another Post",
                  "slug" => "another-post",
                  "status" => "published",
                  "published_at" => "2025-05-02T12:00:00.000Z",
                  "html" => "<h1>Another Post</h1><p>This post has HTML content.</p>"
                },
                {
                  "id" => "3",
                  "title" => "Draft Post",
                  "slug" => "draft-post",
                  "status" => "draft",
                  "html" => "<h1>Draft Post</h1><p>This is a draft post.</p>"
                }
              ],
              "tags" => [
                {
                  "id" => "1",
                  "name" => "test"
                },
                {
                  "id" => "2",
                  "name" => "ruby"
                }
              ],
              "posts_tags" => [
                {
                  "post_id" => "1",
                  "tag_id" => "1"
                },
                {
                  "post_id" => "1",
                  "tag_id" => "2"
                }
              ]
            }
          }
        ]
      }

      File.write(file_path, ghost_data.to_json)
    end
  end
end
