class AddFieldsToPages < ActiveRecord::Migration
  def self.up
    add_column :pages, :show_newsletter_signup, :boolean, :default => false
    add_column :pages, :side_column_content, :text
  end

  def self.down
    remove_column :pages, :show_newsletter_signup
    remove_column :pages, :side_column_content
  end
end
