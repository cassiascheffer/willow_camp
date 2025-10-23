class Blogs::BaseController < ApplicationController
  include SecureDomainRedirect

  layout "blog"
  before_action :set_author
  before_action :disable_session

  private

  def set_author
    set_author_with_secure_redirect
  end

  def disable_session
    # Don't send session cookies for public blog pages
    # This allows Cloudflare to cache HTML responses
    request.session_options[:skip] = true
  end
end
