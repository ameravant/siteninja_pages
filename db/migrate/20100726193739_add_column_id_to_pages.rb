class AddColumnIdToPages < ActiveRecord::Migration
  def self.up
    add_column :pages, :column_id, :integer, :default => 1
    p = Page.find_by_permalink("blog")
    p.update_attributes(:column_id => 2) unless p.blank?
  end

  def self.down
    remove_column :pages, :column_id
  end
end
