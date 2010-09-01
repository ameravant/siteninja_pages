class AddShowCommentDisclaimerToPages < ActiveRecord::Migration
  def self.up
    add_column :pages, :show_comment_disclaimer, :boolean, :default => true
  end

  def self.down
    remove_column :pages, :show_comment_disclaimer
  end
end
