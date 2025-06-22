class Dashboard::PostsController < Dashboard::BaseController
  before_action :set_post, only: %i[edit update destroy]
  before_action :authorize_user!, only: %i[edit update destroy]

  def new
    @post = current_user.posts.build
  end

  def create
    @post = current_user.posts.build(post_params)
    prepare_post_for_save

    if @post.save
      handle_successful_create
    else
      handle_failed_create
    end
  end

  def edit
  end

  def update
    prepare_post_for_save

    if @post.update(post_params)
      handle_successful_update
    else
      handle_failed_update
    end
  end

  def destroy
    @post.destroy!
    redirect_to dashboard_path, notice: "Post deleted successfully"
  end

  private

  def set_post
    @post = current_user.posts.find_by!(slug: params[:slug])
  end

  def authorize_user!
    redirect_to dashboard_path, alert: "Unauthorized" unless @post.author == current_user
  end

  def post_params
    params.require(:post).permit(
      :title, :tag_list, :slug, :body_markdown, :published,
      :published_at, :meta_description
    )
  end

  def prepare_post_for_save
    # Auto-fill title if blank (especially for auto-saves)
    @post.title = "Untitled" if @post.title.blank?

    # Generate slug for new posts or when title changes significantly
    if @post.slug.blank? || (!auto_save_request? && title_changed_significantly?)
      @post.slug = @post.title.parameterize
    end
  end

  def handle_successful_create
    if auto_save_request?
      # For auto-saves, redirect to edit page so future saves can update
      redirect_to edit_dashboard_post_path(@post.slug), status: :see_other
    elsif manual_save_request?
      # For manual saves (Cmd+S), stay on edit page
      redirect_to edit_dashboard_post_path(@post.slug), notice: "Post created successfully!"
    else
      # Regular form submission - go to dashboard
      redirect_to dashboard_path, notice: "Post created successfully!"
    end
  end

  def handle_failed_create
    if auto_save_request?
      head :unprocessable_entity
    else
      flash.now[:alert] = "There were errors creating the post"
      render :new, status: :unprocessable_entity
    end
  end

  def handle_successful_update
    if auto_save_request?
      # For auto-saves, just return success status
      head :ok
    elsif manual_save_request?
      # For manual saves (Cmd+S), stay on the same page
      redirect_to edit_dashboard_post_path(@post.slug), notice: "Post saved successfully!"
    else
      # Regular form submission - go to dashboard
      redirect_to dashboard_path, notice: "Post updated successfully!"
    end
  end

  def handle_failed_update
    if auto_save_request?
      head :unprocessable_entity
    else
      flash.now[:alert] = "There were errors updating the post"
      render :edit, status: :unprocessable_entity
    end
  end

  def auto_save_request?
    params[:auto_save].present?
  end

  def manual_save_request?
    params[:manual_save].present?
  end

  def title_changed_significantly?
    return false unless @post.persisted? && @post.title_changed?

    # Only update slug if the change is significant (not just whitespace/case)
    old_slug = @post.title_was&.parameterize
    new_slug = @post.title.parameterize
    old_slug != new_slug
  end
end
