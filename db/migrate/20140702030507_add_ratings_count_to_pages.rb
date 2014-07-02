class AddRatingsCountToPages < ActiveRecord::Migration
  def self.up
    add_column :pages, :ratings_count, :integer
  end

  def self.down
    remove_column :pages, :ratings_count
  end
end