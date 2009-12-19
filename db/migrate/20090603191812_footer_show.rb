class FooterShow < ActiveRecord::Migration
  def self.up
    add_column :pages, :show_in_footer, :boolean, :default => 1
    add_column :pages, :footer_pos, :integer
  end

  def self.down
    remove_column :pages, :show_in_footer
    remove_column :pages, :footer_pos
  end
end
