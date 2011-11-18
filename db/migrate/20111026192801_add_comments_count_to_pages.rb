class AddCommentsCountToPages < ActiveRecord::Migration
  def self.up
    add_column :pages, :comments_count, :integer
    add_column :pages, :show_comments, :boolean, :default => false
  end

  def self.down
    remove_column :pages, :show_comments
    remove_column :pages, :comments_count
  end
end