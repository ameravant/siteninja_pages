class ShowTestimonialsAndArticleCategories < ActiveRecord::Migration
  def self.up
    add_column :pages, :show_article_cats, :boolean
    add_column :pages, :show_testimonials, :boolean
  end

  def self.down
    add_column :pages, :show_article_cats
    add_column :pages, :show_testimonials
  end
end

