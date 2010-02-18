class MigratePagesToNavigation < ActiveRecord::Migration
  def self.up
    unless ActiveRecord::Base.connection.tables.include?("menus")
      add_column :pages, :menus_count, :integer, :default => 0
    end
  end

  def self.down
    unless ActiveRecord::Base.connection.tables.include?("menus")
      remove_column :pages, :menus_count
    end
  end
end
