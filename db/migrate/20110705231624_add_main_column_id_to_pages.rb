class AddMainColumnIdToPages < ActiveRecord::Migration
  def self.up
    add_column :pages, :main_column_id, :integer
    
    homepage_column = Column.create(:title => "Homepage", :column_location => "main_column", :can_delete => false)
    ColumnSection.create(:title => "Feature Box", :column_section_type_id => feature.id, :column_id => homepage_column.id, :position => 1)
    ColumnSection.create(:title => "Body Content", :column_section_type_id => body_column.id, :column_id => homepage_column.id, :position => 2)
    default_column = Column.create(:title => "Default", :column_location => "main_column", :can_delete => false)
    ColumnSection.create(:title => "Body Content", :column_section_type_id => body_column.id, :column_id => default_column.id, :position => 1)
    homepage = Page.find_by_permalink("home")
    pages = Page.all(:conditions => ["permalink != ?", "home"])
    for page in pages
      page.main_column_id = default_column.id
      page.save
    end
    homepage.update_attributes(:main_column_id => homepage_column.id)
  end

  def self.down
    remove_column :pages, :main_column_id
  end
end
