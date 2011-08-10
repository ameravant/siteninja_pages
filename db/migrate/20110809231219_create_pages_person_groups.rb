class CreatePagesPersonGroups < ActiveRecord::Migration
  def self.up
    create_table :pages_person_groups, :id => false do |t|
      t.integer :person_group_id
      t.integer :page_id
    end
  end

  def self.down
    drop_table :pages_person_groups
  end
end
