class AddFootTextToPages < ActiveRecord::Migration
  def self.up
    add_column :pages, :foot_text, :text
  end

  def self.down
    remove_column :pages, :foot_text
  end
end