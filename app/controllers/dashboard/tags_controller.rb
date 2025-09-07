module Dashboard
  class TagsController < BaseController
    def index
      @user = current_user
      # @blog is already set by BaseController
      @tags = @blog&.all_tags_with_published_and_draft_counts || []
    end

    def update
      @tag = find_user_tag(params[:id])

      if @tag.update(tag_params)
        respond_to do |format|
          format.turbo_stream do
            # Get updated count after renaming
            updated_tag = @blog.all_tags_with_published_and_draft_counts.find(@tag.id)
            # Replace both mobile card and desktop row
            render turbo_stream: [
              turbo_stream.replace("tag_#{@tag.id}",
                partial: "tag_card", locals: {tag: updated_tag}),
              turbo_stream.replace("tag_row_#{@tag.id}",
                partial: "tag_row", locals: {tag: updated_tag})
            ]
          end
        end
      else
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: turbo_stream.replace("tag_#{@tag.id}_form",
              partial: "tag_form", locals: {tag: @tag})
          end
        end
      end
    end

    def destroy
      @tag = find_user_tag(params[:id])

      if @tag.destroy
        respond_to do |format|
          format.turbo_stream do
            # Remove both mobile card and desktop row
            render turbo_stream: [
              turbo_stream.remove("tag_#{@tag.id}"),
              turbo_stream.remove("tag_row_#{@tag.id}")
            ]
          end
        end
      else
        respond_to do |format|
          format.turbo_stream do
            # Show error on both mobile and desktop views
            render turbo_stream: [
              turbo_stream.replace("tag_#{@tag.id}",
                partial: "tag_card", locals: {tag: @tag}),
              turbo_stream.replace("tag_row_#{@tag.id}",
                partial: "tag_row", locals: {tag: @tag})
            ]
          end
        end
      end
    end

    private

    def find_user_tag(tag_id)
      # Only allow editing tags that are used by the current blog's posts
      user_tag_ids = @blog&.all_tags_with_published_and_draft_counts&.pluck(:id) || []
      tag = ActsAsTaggableOn::Tag.find(tag_id)

      unless user_tag_ids.include?(tag.id)
        raise ActiveRecord::RecordNotFound
      end

      tag
    end

    def tag_params
      params.require(:tag).permit(:name)
    end
  end
end
