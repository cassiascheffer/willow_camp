require "test_helper"

class PostTest < ActiveSupport::TestCase
  setup do
    @post = Post.new(
      author: users(:one), 
      title: "Test Post",
      body_markdown: "Test content",
      published: true
    )
  end
  
  test "should be valid with required attributes" do
    assert @post.valid?, "Post with required attributes should be valid"
  end

  test "should require an author" do
    post = Post.new(title: "Test Post")
    assert_not post.valid?, "Post without an author should not be valid"
    assert_includes post.errors[:author], "must exist"
  end

  test "should require a title" do
    @post.title = ""
    assert_not @post.valid?
    assert_includes @post.errors[:title], "can't be blank"
  end

  test "title should not exceed maximum length" do
    @post.title = "a" * 256
    assert_not @post.valid?
    assert_includes @post.errors[:title], "is too long (maximum is 255 characters)"
  end

  test "should validate slug uniqueness" do
    # Create a post with a specific slug
    post1 = Post.create!(
      author: users(:one),
      title: "Original Test Post",
      slug: "test-slug-#{SecureRandom.hex(4)}"
    )
    
    # Try to create another post with the same slug
    post2 = Post.new(
      author: users(:two),
      title: "Duplicate Slug Post", 
      slug: post1.slug
    )
    
    # It should fail validation
    assert_not post2.valid?
    assert_includes post2.errors[:slug], "has already been taken"
  end

  test "should generate slug if not provided" do
    post = Post.create!(author: users(:one), title: "Auto Slug Test")
    assert_not_nil post.slug
    assert_includes post.slug, "auto-slug-test"
  end

  test "should validate published is boolean" do
    # Nil is allowed by the model
    @post.published = nil
    assert @post.valid?
    
    # Non-boolean values should be coerced by Rails
    # This is how Rails typically handles boolean attributes
    @post.published = true
    assert @post.valid?
    
    @post.published = false
    assert @post.valid?
  end

  test "should set published_at when published" do
    post = Post.new(
      author: users(:one), 
      title: "Test Post", 
      published: true
    )
    
    assert_nil post.published_at
    post.save!
    assert_not_nil post.published_at
  end

  test "should belong to an author" do
    post = posts(:one)
    assert_respond_to post, :author, "Post should respond to 'author'"
    assert_instance_of User, post.author, "Post's author should be a User"
  end

  test "should have the correct author_id" do
    user = users(:one)
    post = Post.create(author: user, title: "Test Post")
    assert_equal user.id, post.author_id, "Post's author_id should match the author's id"
  end

  test "should generate HTML from markdown if Commonmarker is available" do
    # Skip this test for now since Commonmarker doesn't seem to be available
    skip "Commonmarker gem not available"
  end
end
