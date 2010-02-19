class MigratePagesToNavigation < ActiveRecord::Migration
  def self.up
    begin
      add_column :pages, :menus_count, :integer, :default => 0
    rescue
      #do nothing
    end
  end

  def self.down
    begin
      remove_column :pages, :menus_count
    rescue
      #do nothing
    end
  end
end
