require "test_helper"
require "stringio"
require "webmock/minitest"

module WillowCampCLI
  class CLITest < Minitest::Test
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

      # Reset any webmock stubs
      WebMock.reset!
    end

    def teardown
      # Restore stdout
      $stdout = @original_stdout
    end

    def test_initialization
      cli = CLI.new(@base_options.merge(slug: "test-post"))

      assert_equal CLI::API_URL, "https://willow.camp/"
      assert_equal @token, cli.token
      assert_equal false, cli.verbose
    end

    def test_list_posts
      # Stub the API request
      posts_data = {
        "posts" => [
          {"id" => 1, "slug" => "post-1"},
          {"id" => 2, "slug" => "post-2"}
        ]
      }

      stub_request(:get, "#{CLI::API_URL}/api/posts")
        .with(headers: {"Authorization" => "Bearer #{@token}"})
        .to_return(status: 200, body: posts_data.to_json)

      cli = CLI.new(@base_options)
      cli.list_posts

      output = $stdout.string
      assert_match(/Found 2 post\(s\)/, output)
      assert_match(/\[1\] post-1/, output)
      assert_match(/\[2\] post-2/, output)
    end

    def test_list_posts_empty
      # Stub the API request with empty results
      stub_request(:get, "#{CLI::API_URL}/api/posts")
        .with(headers: {"Authorization" => "Bearer #{@token}"})
        .to_return(status: 200, body: {"posts" => []}.to_json)

      cli = CLI.new(@base_options)
      cli.list_posts

      output = $stdout.string
      assert_match(/No posts found/, output)
    end

    def test_show_post
      post_data = {
        "post" => {
          "id" => 1,
          "slug" => "test-post",
          "title" => "Test Post",
          "published" => true,
          "published_at" => "2025-05-20T12:00:00Z",
          "tag_list" => ["test", "ruby"],
          "markdown" => "# Test Post\n\nThis is a test post."
        }
      }

      stub_request(:get, "#{CLI::API_URL}/api/posts/test-post")
        .with(headers: {"Authorization" => "Bearer #{@token}"})
        .to_return(status: 200, body: post_data.to_json)

      cli = CLI.new(@base_options.merge(slug: "test-post"))
      cli.show_post

      output = $stdout.string
      assert_match(/Test Post/, output)
      assert_match(/Published: true/, output)
      assert_match(/Tags: test, ruby/, output)
    end

    def test_show_post_with_verbose
      post_data = {
        "post" => {
          "id" => 1,
          "slug" => "test-post",
          "title" => "Test Post",
          "markdown" => "# Test Content"
        }
      }

      stub_request(:get, "#{CLI::API_URL}/api/posts/test-post")
        .with(headers: {"Authorization" => "Bearer #{@token}"})
        .to_return(status: 200, body: post_data.to_json)

      cli = CLI.new(@base_options.merge(slug: "test-post", verbose: true))
      cli.show_post

      output = $stdout.string
      assert_match(/Content:/, output)
      assert_match(/# Test Content/, output)
    end

    def test_show_post_no_slug
      cli = CLI.new(@base_options)
      cli.show_post

      output = $stdout.string
      assert_match(/Error: Slug is required/, output)
    end

    def test_update_post
      stub_request(:patch, "#{CLI::API_URL}/api/posts/test-post")
        .with(
          headers: {"Authorization" => "Bearer #{@token}"},
          body: {post: {markdown: "# Updated Content"}}.to_json
        )
        .to_return(status: 200, body: {
          "post" => {
            "slug" => "test-post",
            "title" => "Test Post"
          }
        }.to_json)

      cli = CLI.new(@base_options.merge(slug: "test-post"))
      cli.update_post("# Updated Content")

      output = $stdout.string
      assert_match(/Successfully updated post/, output)
    end

    def test_update_post_dry_run
      cli = CLI.new(@base_options.merge(slug: "test-post", dry_run: true))
      cli.update_post("# Test Content")

      output = $stdout.string
      assert_match(/DRY RUN: Would update post test-post/, output)
    end

    def test_update_post_no_slug
      cli = CLI.new(@base_options)
      cli.update_post("# Test Content")

      output = $stdout.string
      assert_match(/Error: Slug and content are required/, output)
    end

    def test_delete_post
      stub_request(:delete, "#{CLI::API_URL}/api/posts/test-post")
        .with(headers: {"Authorization" => "Bearer #{@token}"})
        .to_return(status: 204)

      cli = CLI.new(@base_options.merge(slug: "test-post"))
      cli.delete_post

      output = $stdout.string
      assert_match(/Successfully deleted post/, output)
    end

    def test_delete_post_dry_run
      cli = CLI.new(@base_options.merge(slug: "test-post", dry_run: true))
      cli.delete_post

      output = $stdout.string
      assert_match(/DRY RUN: Would delete post test-post/, output)
    end

    def test_delete_post_no_slug
      cli = CLI.new(@base_options)
      cli.delete_post

      output = $stdout.string
      assert_match(/Error: Slug is required/, output)
    end

    def test_upload_file
      test_file = "test.md"
      test_content = "# Test Post"

      File.stub :read, test_content do
        stub_request(:post, "#{CLI::API_URL}/api/posts")
          .with(
            headers: {"Authorization" => "Bearer #{@token}"},
            body: {post: {markdown: test_content}}.to_json
          )
          .to_return(status: 200, body: {
            "post" => {
              "slug" => "test-post",
              "title" => "Test Post"
            }
          }.to_json)

        cli = CLI.new(@base_options)
        cli.upload_file(test_file)

        output = $stdout.string
        assert_match(/Successfully uploaded/, output)
        assert_match(/Created post 'Test Post'/, output)
      end
    end

    def test_upload_file_dry_run
      test_file = "test.md"
      test_content = "# Test Post"

      File.stub :read, test_content do
        cli = CLI.new(@base_options.merge(dry_run: true))
        cli.upload_file(test_file)

        output = $stdout.string
        assert_match(/DRY RUN: Would upload test.md/, output)
      end
    end

    def test_upload_all
      test_files = ["file1.md", "file2.md"]

      cli = CLI.new(@base_options)

      cli.stub :find_markdown_files, test_files do
        cli.stub :upload_file, nil do
          cli.upload_all

          output = $stdout.string
          assert_match(/Found 2 Markdown file\(s\)/, output)
          assert_match(/\[1\/2\] Processing file1.md/, output)
          assert_match(/\[2\/2\] Processing file2.md/, output)
        end
      end
    end

    def test_upload_all_no_files
      cli = CLI.new(@base_options)

      cli.stub :find_markdown_files, [] do
        cli.upload_all

        output = $stdout.string
        assert_match(/No Markdown files found/, output)
      end
    end

    def test_download_post
      post_content = "# Test Post\n\nContent"
      post_data = {
        "post" => {
          "slug" => "test-post",
          "markdown" => post_content
        }
      }

      stub_request(:get, "#{CLI::API_URL}/api/posts/test-post")
        .with(headers: {"Authorization" => "Bearer #{@token}"})
        .to_return(status: 200, body: post_data.to_json)

      File.stub :write, nil do
        cli = CLI.new(@base_options.merge(slug: "test-post"))
        cli.download_post("output.md")

        output = $stdout.string
        assert_match(/Successfully downloaded post/, output)
      end
    end

    def test_download_post_no_slug
      cli = CLI.new(@base_options)
      cli.download_post("output.md")

      output = $stdout.string
      assert_match(/Error: Slug is required/, output)
    end

    def test_api_request_success
      stub_request(:get, "#{CLI::API_URL}/test-endpoint")
        .with(headers: {"Authorization" => "Bearer #{@token}"})
        .to_return(status: 200, body: '{"success":true}')

      cli = CLI.new(@base_options)
      response = cli.send(:api_request, :get, "/test-endpoint")

      assert_equal 200, response.code.to_i
      assert_equal '{"success":true}', response.body
    end

    def test_api_request_failure
      stub_request(:get, "#{CLI::API_URL}/test-endpoint")
        .with(headers: {"Authorization" => "Bearer #{@token}"})
        .to_return(status: 404, body: '{"error":"Not found"}')

      cli = CLI.new(@base_options)
      response = cli.send(:api_request, :get, "/test-endpoint")

      assert_nil response
      assert_match(/API request failed: HTTP 404/, $stdout.string)
    end

    def test_api_request_network_error
      stub_request(:get, "#{CLI::API_URL}/test-endpoint")
        .to_raise(StandardError.new("Network error"))

      cli = CLI.new(@base_options)
      response = cli.send(:api_request, :get, "/test-endpoint")

      assert_nil response
      assert_match(/Error making API request/, $stdout.string)
    end

    def test_find_markdown_files
      cli = CLI.new(@base_options)

      Dir.stub :glob, ["file1.md", "file2.md"] do
        files = cli.send(:find_markdown_files)
        assert_equal ["file1.md", "file2.md"], files
      end
    end

    def test_run_with_invalid_command
      result = CLI.run(["invalid"], true)

      assert_equal false, result
      assert_match(/Unknown command: invalid/, $stdout.string)
    end

    def test_run_with_list_command
      mock_cli = Minitest::Mock.new
      mock_cli.expect :list_posts, nil

      CLI.stub :new, mock_cli do
        CLI.run(["list", "--token", @token])
      end

      mock_cli.verify
    end

    def test_run_with_show_command
      mock_cli = Minitest::Mock.new
      mock_cli.expect :show_post, nil

      CLI.stub :new, mock_cli do
        CLI.run(["show", "--token", @token, "--slug", "test-post"])
      end

      mock_cli.verify
    end

    def test_run_with_create_command
      test_file = "test.md"
      test_content = "# Test Content"

      File.stub :read, test_content do
        mock_cli = Minitest::Mock.new
        mock_cli.expect :upload_file, nil, [test_file]

        CLI.stub :new, mock_cli do
          CLI.run(["create", "--token", @token, "--file", test_file])
        end

        mock_cli.verify
      end
    end

    def test_run_with_update_command
      test_file = "test.md"
      test_content = "# Test Content"

      File.stub :read, test_content do
        mock_cli = Minitest::Mock.new
        mock_cli.expect :update_post, nil, [test_content]

        CLI.stub :new, mock_cli do
          CLI.run(["update", "--token", @token, "--slug", "test-post", "--file", test_file])
        end

        mock_cli.verify
      end
    end

    def test_run_with_delete_command
      mock_cli = Minitest::Mock.new
      mock_cli.expect :delete_post, nil

      CLI.stub :new, mock_cli do
        CLI.run(["delete", "--token", @token, "--slug", "test-post"])
      end

      mock_cli.verify
    end

    def test_run_with_upload_command
      mock_cli = Minitest::Mock.new
      mock_cli.expect :upload_all, nil

      CLI.stub :new, mock_cli do
        CLI.run(["upload", "--token", @token, "--directory", "posts"])
      end

      mock_cli.verify
    end

    def test_run_with_download_command
      mock_cli = Minitest::Mock.new
      mock_cli.expect :download_post, nil, ["output.md"]

      CLI.stub :new, mock_cli do
        CLI.run(["download", "--token", @token, "--slug", "test-post", "--output", "output.md"])
      end

      mock_cli.verify
    end
  end
end
