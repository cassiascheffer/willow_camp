class AddHasMermaidToPosts < ActiveRecord::Migration[8.0]
  def change
    add_column :posts, :has_mermaid_diagrams, :boolean, default: false, null: false
  end
end
