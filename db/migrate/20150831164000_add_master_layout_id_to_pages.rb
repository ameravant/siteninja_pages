class AddMasterLayoutIdToPages < ActiveRecord::Migration
  def self.up
    add_column :pages, :master_layout_id, :integer
  end

  def self.down
  	remove_column :pages, :master_layout_id
  end
end
