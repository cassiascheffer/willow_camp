class Dashboard::Settings::AboutPagesController < Dashboard::BaseController
  before_action :set_page, only: [:update, :destroy]

  def create
    @page = current_user.pages.new(page_params)
    if @page.save
      respond_to do |format|
        format.html { redirect_to dashboard_settings_path, notice: "Created!" }
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
        format.html { redirect_to dashboard_settings_path, notice: "Updated!" }
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
    @page.destroy
    respond_to do |format|
      format.html { redirect_to dashboard_settings_path, notice: "Page was successfully deleted." }
      format.turbo_stream {
        flash.now[:notice] = "Page was successfully deleted."
        @about_page = current_user.pages.find_or_create_by(title: "About", slug: "about")
      }
    end
  end

  private

  def set_page
    @page = current_user.pages.find_by!(slug: params[:slug], author_id: current_user.id)
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
