class Dashboard::Settings::AboutPagesController < Dashboard::BaseController
  before_action :set_page, only: [:update, :destroy]

  def create
    @page = @blog.pages.new(page_params)
    if @page.save
      respond_to do |format|
        format.html { redirect_to blog_dashboard_settings_path(@blog.subdomain), notice: "Created!" }
        format.turbo_stream {
          flash.now[:notice] = "You now have an about page. Nice!"
        }
      end
    else
      respond_to do |format|
        format.html { render :new }
        format.turbo_stream { render turbo_stream: turbo_stream.replace("about-page-form", partial: "dashboard/settings/page_form", locals: {page: @page}) }
      end
    end
  end

  def update
    if @page.update(page_params)
      respond_to do |format|
        format.html { redirect_to blog_dashboard_settings_path(@blog.subdomain), notice: "Updated!" }
        format.turbo_stream {
          flash.now[:notice] = "Updated!"
        }
      end
    else
      respond_to do |format|
        format.html { render :edit }
        format.turbo_stream { render turbo_stream: turbo_stream.replace("about-page-form", partial: "dashboard/settings/page_form", locals: {page: @page}) }
      end
    end
  end

  def destroy
    @page.slug
    @page.destroy
    respond_to do |format|
      format.html { redirect_to blog_dashboard_settings_path(@blog.subdomain), notice: "Page was successfully deleted." }
      format.turbo_stream {
        flash.now[:notice] = "Page was successfully deleted."
        # Always set @about_page - recreate if about page was deleted, otherwise find existing
        @about_page = @blog.pages.find_or_create_by(title: "About", slug: "about")
      }
    end
  end

  private

  def set_page
    @page = @blog.pages.find_by!(slug: params[:slug])
  end

  def page_params
    params.require(:page).permit(
      :title,
      :body_markdown,
      :published,
      :slug
    )
  end
end
