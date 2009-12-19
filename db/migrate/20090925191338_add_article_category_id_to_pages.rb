class AddArticleCategoryIdToPages < ActiveRecord::Migration
  def self.up
    add_column :pages, :article_category_id, :integer
  end

  def self.down
    remove_column :pages, :article_category_id
  end
end
