class AddRenderedBodyToPages < ActiveRecord::Migration
  def self.up
  	add_column :pages, :rendered_body, :text
  end

  def self.down
  	remove_column :pages, :rendered_body
  end
end
