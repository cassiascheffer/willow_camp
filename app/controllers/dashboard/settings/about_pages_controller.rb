class Dashboard::Settings::AboutPagesController < Dashboard::BaseController
  before_action :set_page, only: [:update, :destroy]

  def create
    @page = @user.pages.new(page_params)
    if @page.save
      respond_to do |format|
        format.html { redirect_to dashboard_settings_path, notice: "Created!" }
        format.turbo_stream {
          render turbo_stream: [
            turbo_stream.replace("about-page-form", partial: "dashboard/settings/page_form", locals: {page: @page}),
            turbo_stream.prepend("flash-messages", partial: "shared/flash", locals: {type: "notice", message: "You now have an about page. Nice!"})
          ]
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
          render turbo_stream: [
            turbo_stream.replace("about-page-form", partial: "dashboard/settings/page_form", locals: {page: @page}),
            turbo_stream.prepend("flash-messages", partial: "shared/flash", locals: {type: "notice", message: "Updated!"})
          ]
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
    redirect_to dashboard_settings_about_pages_path, notice: "Page was successfully deleted."
  end

  private

  def set_page
    @page = @user.pages.find_by!(slug: params[:slug], author_id: @user.id)
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
