class AddFeatureTestimonialToPages < ActiveRecord::Migration
  def self.up
    add_column :pages, :show_featured_testimonial, :boolean, :default => true 
  end

  def self.down
    remove_column :pages, :show_featured_testimonial
  end
end
