class CreatePages < ActiveRecord::Migration
  def self.up
    create_table :pages do |t|
      t.string :title, :permalink
      t.string :meta_title, :meta_keywords, :meta_description
      t.string :status, :default => "visible" # visible, hidden
      t.text :body
      t.integer :parent_id
      t.integer :images_count, :features_count, :testimonials_count, :default => 0
      t.integer :position, :default => 1
      t.boolean :show_articles, :show_events, :default => true
      t.boolean :automatically_embed_videos_and_images, :default => true
      t.boolean :can_delete, :can_edit_content, :show_in_menu, :default => true
      t.timestamps
    end
  end

  def self.down
    drop_table :pages
  end
end
