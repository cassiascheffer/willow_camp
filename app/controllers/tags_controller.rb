class TagsController < ApplicationController
  include SecureDomainRedirect

  before_action :set_author, only: %i[index show]
  before_action :set_tag, only: [:show]

  def index
    @tags = ActsAsTaggableOn::Tag.for_tenant(@author.id)
  end

  def show
    @pagy, @posts = pagy(
      Post.published.where(author: @author).tagged_with(@tag.name).order(created_at: :desc)
    )
  end

  private

  def set_tag
    @tag = ActsAsTaggableOn::Tag.for_tenant(@author.id).friendly.find(params[:tag])
  rescue ActiveRecord::RecordNotFound
    redirect_to root_url
  end

  def set_author
    set_author_with_secure_redirect
  end
end
