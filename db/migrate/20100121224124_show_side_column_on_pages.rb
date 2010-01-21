class ShowSideColumnOnPages < ActiveRecord::Migration
  def self.up
    add_column :pages, :show_side_column_text, :boolean, :default => false
  end

  def self.down
    remove_column :pages, :show_side_column_text
  end
end
