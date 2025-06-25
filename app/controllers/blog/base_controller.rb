class Blog::BaseController < ApplicationController
  include SecureDomainRedirect
  layout "blog"
  before_action :set_author

  private

  def set_author
    set_author_with_secure_redirect
  end
end
