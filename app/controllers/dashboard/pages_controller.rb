class Dashboard::PagesController < Dashboard::BaseController
  before_action :set_page, only: [:show, :edit, :update, :destroy]

  def index
    @pagy, @pages = pagy(@user.pages)
  end

  def new
    @page = @user.pages.new
  end

  def create
    @page = @user.pages.new(page_params)
    if @page.save
      redirect_to dashboard_page_path(@page), notice: "Page was successfully created."
    else
      render :new
    end
  end

  def show
  end

  def edit
  end

  def update
    if @page.update(page_params)
      redirect_to dashboard_page_path(@page), notice: "Page was successfully updated."
    else
      render :edit
    end
  end

  def destroy
    @page.destroy
    redirect_to dashboard_pages_path, notice: "Page was successfully deleted."
  end

  private

  def set_page
    @page = Page.find_by!(slug: params[:slug], author_id: @user.id)
  end

  def page_params
    params.require(:page).permit(
      :title,
      :slug,
      :body_markdown,
      :published,
      :published_at,
      :updated_at,
      :meta_description
    )
  end
end
