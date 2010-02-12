class MigratePagesToNavigation < ActiveRecord::Migration
  def self.up
    add_column :pages, :menus_count, :integer, :default => 0
    for page in Page.all
      if page.menus.empty?
        menu = page.menus.new
        menu.save
      end
    end
    for menu in Menu.all
      page = menu.navigatable
      unless page.parent_id.blank?
        parent_page = Page.find(page.parent_id)
        menu.parent_id = parent_page.menus.first.id
      end
      menu.position = page.position
      menu.footer_pos = page.footer_pos
      menu.show_in_footer = page.show_in_footer
      menu.can_delete = page.can_delete
      menu.status = page.status
      menu.save
    end
  end

  def self.down
    remove_column :pages, :menus_count
  end
end
