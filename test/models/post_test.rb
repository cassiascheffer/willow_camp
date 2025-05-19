require "test_helper"

class PostTest < ActiveSupport::TestCase
  test "should be valid with required attributes" do
    post = Post.new(author: users(:one))
    # Add any other required attributes here
    assert post.valid?, "Post with required attributes should be valid"
  end

  test "should require an author" do
    post = Post.new
    assert_not post.valid?, "Post without an author should not be valid"
    assert_includes post.errors[:author], "must exist"
  end

  test "should belong to an author" do
    post = posts(:one)
    assert_respond_to post, :author, "Post should respond to 'author'"
    assert_instance_of User, post.author, "Post's author should be a User"
  end

  test "should have the correct author_id" do
    user = users(:one)
    post = Post.create(author: user)
    assert_equal user.id, post.author_id, "Post's author_id should match the author's id"
  end
end
