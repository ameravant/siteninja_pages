class AddShowSearchToPages < ActiveRecord::Migration
  def self.up
    add_column :pages, :show_site_search, :boolean, :default => true
  end

  def self.down
    remove_column :pages, :show_site_search
  end
end
