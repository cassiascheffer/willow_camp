class TagsController < ApplicationController
  allow_unauthenticated_access only: %i[ index show ]
  before_action :set_author, only: %i[ index show ]
  before_action :set_tag, only: [ :show ]

  def index
    @tags = ActsAsTaggableOn::Tag.for_tenant(@author.id)
  end

  def show
    @posts = Post.where(author: @author).tagged_with(@tag.name).order(created_at: :desc)
  end

  private

  def set_tag
    @tag = ActsAsTaggableOn::Tag.for_tenant(@author.id).find_by(name: params[:tag])
    if @tag.nil?
      redirect_to root_url
    end
  end

  def set_author
    @author = User.find_by(subdomain: request.subdomain)
    if @author.nil?
      redirect_to root_url(subdomain: false, allow_other_host: true)
    end
  end
end
