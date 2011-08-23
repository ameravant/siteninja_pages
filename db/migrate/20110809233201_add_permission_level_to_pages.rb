class AddPermissionLevelToPages < ActiveRecord::Migration
  def self.up
    add_column :pages, :permission_level, :string, :default => "everyone"
  end

  def self.down
    remove_column :pages, :permission_level
  end
end
