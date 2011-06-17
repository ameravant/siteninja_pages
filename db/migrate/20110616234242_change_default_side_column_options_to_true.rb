class ChangeDefaultSideColumnOptionsToTrue < ActiveRecord::Migration
  def self.up
    change_column :pages, :show_newsletter_signup, :boolean, :default => true
    change_column :pages, :show_side_column_text, :boolean, :default => true
    change_column :pages, :show_article_cats, :boolean, :default => true
  end

  def self.down
    change_column :pages, :show_newsletter_signup, :boolean, :default => false
    change_column :pages, :show_side_column_text, :boolean, :default => false
    change_column :pages, :show_article_cats, :boolean, :default => false
  end
end
