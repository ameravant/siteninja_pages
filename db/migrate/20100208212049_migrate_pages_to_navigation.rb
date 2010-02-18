class MigratePagesToNavigation < ActiveRecord::Migration
  def self.up
    add_column :pages, :menus_count, :integer, :default => 0
  end

  def self.down
    remove_column :pages, :menus_count
  end
end
