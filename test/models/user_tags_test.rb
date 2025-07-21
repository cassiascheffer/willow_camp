require "test_helper"

class UserTagsTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(
      email: "test@example.com",
      password: "password123",
      name: "Test User",
      subdomain: "testuser"
    )
  end

  test "all_tags returns unique tags from user's posts" do
    post1 = @user.posts.create!(title: "Post 1", body_markdown: "Content", published: true)
    post1.tag_list = "ruby, rails, programming"
    post1.save!

    post2 = @user.posts.create!(title: "Post 2", body_markdown: "Content", published: true)
    post2.tag_list = "ruby, javascript"
    post2.save!

    tags = @user.all_tags.pluck(:name)

    assert_equal 4, tags.count
    assert_includes tags, "ruby"
    assert_includes tags, "rails"
    assert_includes tags, "programming"
    assert_includes tags, "javascript"
  end

  test "tags_with_counts returns tags with correct usage counts" do
    post1 = @user.posts.create!(title: "Post 1", body_markdown: "Content", published: true)
    post1.tag_list = "ruby, rails"
    post1.save!

    post2 = @user.posts.create!(title: "Post 2", body_markdown: "Content", published: true)
    post2.tag_list = "ruby, javascript"
    post2.save!

    post3 = @user.posts.create!(title: "Post 3", body_markdown: "Content", published: true)
    post3.tag_list = "ruby"
    post3.save!

    tags_with_counts = @user.tags_with_counts

    ruby_tag = tags_with_counts.find { |tag| tag.name == "ruby" }
    assert_equal 3, ruby_tag.taggings_count

    rails_tag = tags_with_counts.find { |tag| tag.name == "rails" }
    assert_equal 1, rails_tag.taggings_count

    javascript_tag = tags_with_counts.find { |tag| tag.name == "javascript" }
    assert_equal 1, javascript_tag.taggings_count
  end

  test "tags_with_counts only includes tags from published posts" do
    published_post = @user.posts.create!(title: "Published", body_markdown: "Content", published: true)
    published_post.tag_list = "visible"
    published_post.save!

    draft_post = @user.posts.create!(title: "Draft", body_markdown: "Content", published: false)
    draft_post.tag_list = "hidden"
    draft_post.save!

    tags = @user.tags_with_counts.pluck(:name)

    assert_includes tags, "visible"
    assert_not_includes tags, "hidden"
  end

  test "all_tags_with_counts returns tags with counts from all posts including drafts" do
    published_post = @user.posts.create!(title: "Published", body_markdown: "Content", published: true)
    published_post.tag_list = "ruby, rails"
    published_post.save!

    draft_post = @user.posts.create!(title: "Draft", body_markdown: "Content", published: false)
    draft_post.tag_list = "ruby, javascript"
    draft_post.save!

    another_draft = @user.posts.create!(title: "Another Draft", body_markdown: "Content", published: false)
    another_draft.tag_list = "ruby"
    another_draft.save!

    tags_with_counts = @user.all_tags_with_counts

    ruby_tag = tags_with_counts.find { |tag| tag.name == "ruby" }
    assert_equal 3, ruby_tag.taggings_count, "Ruby should appear in all 3 posts (1 published, 2 drafts)"

    rails_tag = tags_with_counts.find { |tag| tag.name == "rails" }
    assert_equal 1, rails_tag.taggings_count, "Rails should appear in 1 published post"

    javascript_tag = tags_with_counts.find { |tag| tag.name == "javascript" }
    assert_equal 1, javascript_tag.taggings_count, "JavaScript should appear in 1 draft post"

    tag_names = tags_with_counts.pluck(:name)
    assert_includes tag_names, "ruby"
    assert_includes tag_names, "rails"
    assert_includes tag_names, "javascript"
  end

  test "all_tags_with_counts includes draft-only tags" do
    draft_post = @user.posts.create!(title: "Draft Only", body_markdown: "Content", published: false)
    draft_post.tag_list = "draft-only-tag"
    draft_post.save!

    tags_with_counts = @user.all_tags_with_counts
    tag_names = tags_with_counts.pluck(:name)

    assert_includes tag_names, "draft-only-tag"

    draft_tag = tags_with_counts.find { |tag| tag.name == "draft-only-tag" }
    assert_equal 1, draft_tag.taggings_count
  end

  test "all_tags_with_counts orders by usage count descending" do
    post1 = @user.posts.create!(title: "Post 1", body_markdown: "Content", published: true)
    post1.tag_list = "popular, rare"
    post1.save!

    post2 = @user.posts.create!(title: "Post 2", body_markdown: "Content", published: false)
    post2.tag_list = "popular"
    post2.save!

    post3 = @user.posts.create!(title: "Post 3", body_markdown: "Content", published: true)
    post3.tag_list = "popular"
    post3.save!

    tags_with_counts = @user.all_tags_with_counts

    assert_equal "popular", tags_with_counts.first.name, "Most used tag should be first"
    assert_equal 3, tags_with_counts.first.taggings_count

    assert_equal "rare", tags_with_counts.last.name, "Least used tag should be last"
    assert_equal 1, tags_with_counts.last.taggings_count
  end

  test "all_tags_with_counts respects multi-tenancy" do
    other_user = User.create!(
      email: "other@example.com",
      password: "password123",
      name: "Other User",
      subdomain: "otheruser"
    )

    @user.posts.create!(title: "My Post", body_markdown: "Content", published: true, tag_list: "my-tag")
    other_user.posts.create!(title: "Their Post", body_markdown: "Content", published: true, tag_list: "their-tag")

    my_tags = @user.all_tags_with_counts.pluck(:name)
    their_tags = other_user.all_tags_with_counts.pluck(:name)

    assert_includes my_tags, "my-tag"
    assert_not_includes my_tags, "their-tag"
    assert_includes their_tags, "their-tag"
    assert_not_includes their_tags, "my-tag"
  end

  test "tags are scoped per user (multi-tenancy)" do
    other_user = User.create!(
      email: "other@example.com",
      password: "password123",
      name: "Other User",
      subdomain: "otheruser"
    )

    @user.posts.create!(title: "My Post", body_markdown: "Content", published: true, tag_list: "my-tag")
    other_user.posts.create!(title: "Their Post", body_markdown: "Content", published: true, tag_list: "their-tag")

    my_tags = @user.all_tags.pluck(:name)

    assert_includes my_tags, "my-tag"
    assert_not_includes my_tags, "their-tag"
  end
end
