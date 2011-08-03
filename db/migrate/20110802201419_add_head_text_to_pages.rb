class AddHeadTextToPages < ActiveRecord::Migration
  def self.up
    add_column :pages, :head_script, :text
    add_column :pages, :additional_styles, :text
  end

  def self.down
    remove_column :pages, :head_script
    remove_column :pages, :additional_styles
  end
end
