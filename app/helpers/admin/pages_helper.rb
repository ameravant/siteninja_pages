module Admin::PagesHelper

  def build_menu(parent_id=nil)
    children = Menu.all.select { |menu| menu.parent_id == parent_id }
    ul_id = "menu_list_#{parent_id || '0'}"
    unless children.empty?
      concat "<ul id=\"#{ul_id}\" class=\"sortable\">"
      # Output the list elements for these children, and recursively
      # call build_menu for their children.
      for child in children
          status = (child.show_in_main_menu == false and child.show_in_side_column == false and child.show_in_footer == false) ? 'hidden' : 'visible'
          concat "<li id=\"#{dom_id(child)}\" class=\"menu-item\">"
          concat "<div class=\"menu-item-inner #{status}\">"
          concat '<div class="page-handle">' + image_tag("#{move_loc}", :class => "icon handle") + '</div>'
          concat '<div class="page-title">'
          concat link_to(h(child.menu_title), [:edit, :admin, (child.navigatable.blank? ? child : child.navigatable)], :class => child.hidden? ? 'gray' : nil)
          concat ' &mdash; ' + link_to("Manage Homepage Features", admin_features_path) if (child.url == "/")
          concat '</div><div class="page-options">'
          concat feature_icon_select(child.navigatable, child.navigatable.name) unless child.navigatable.blank? or feature_icon_select(child.navigatable, child.navigatable.name).blank?
          concat ' ' + icon("Write", [:edit, :admin, (child.navigatable.blank? ? child : child.navigatable)]) + ' '
          #Check page is allowed to be deleted and provide icon to allow it
          if child.can_delete
            if !child.navigatable.blank? and child.navigatable_type == "Page"
              concat(link_to_remote(
                image_tag("#{icons_loc}/gray/16x16/Trash.png", :class => "icon", :alt => "Delete #{child.menu_title}", :id => "#{dom_id(child)}_trash_icon"),
                {
                  :url => [:admin, child],
                  :method => :delete,
                  :loading => "$('#{dom_id(child)}_trash_icon').src = '#{spinner_loc}'",
                  :failure => "$('#{dom_id(child)}_trash_icon').src = '#{exclamation_loc}'",
                  :success => "$('#{dom_id(child)}_trash_icon').src = '#{ok_loc}'",
                  :confirm => "Really delete #{child.navigatable.title}? There is no undo!",
                  :delay => 1
                }, :class => "icon"))
            else
              concat(link_to_remote(
                image_tag("#{icons_loc}/green/16x16/Link.png", :class => "icon", :alt => "Remove #{child.menu_title} from navigation", :title => "Remove #{child.menu_title} from navigation", :id => "#{dom_id(child)}_trash_icon"),
                {
                  :url => [:admin, child],
                  :method => :delete,
                  :loading => "$('#{dom_id(child)}_trash_icon').src = '#{spinner_loc}'",
                  :failure => "$('#{dom_id(child)}_trash_icon').src = '#{exclamation_loc}'",
                  :success => "$('#{dom_id(child)}_trash_icon').src = '#{ok_loc}'",
                  :confirm => "Really remove #{child.menu_title} from navigation?",
                  :delay => 1
                }, :class => "icon"))
            end
          else
            concat ' ' + "<div style='width: 16px; height: 16px; float: right; margin-left: 4px;'></div>"
          end
          if @cms_config['features']['testimonials']
            concat '</div><div class="page-testimonials">'
            if child.navigatable_type == "Page"
              concat icon("Bubble 1", [:admin, child.navigatable, :testimonials]) + ' ' + link_to(child.navigatable.testimonials_count, [:admin, child.navigatable, :testimonials])
            else
              concat "&nbsp;"
            end
          end
          concat '</div><div class="page-images">'
          concat icon("Picture", [:admin, child.navigatable, :images]) + ' ' + link_to(child.navigatable.images_count, [:admin, child.navigatable, :images]) unless child.navigatable.blank?
          concat '&nbsp;' if child.navigatable.blank?
          concat '</div><div class="page-type">'
          concat (child.navigatable.blank? ? "Link" : child.navigatable.class.to_s)
          concat "</div>" 
          menu_form(child)
          concat clear + "</div>"
          concat "<div class=\"droppable\" id=\"droppable_#{dom_id(child)}\"><span>Drop menu into \"#{child.menu_title}.\"</span></div>"
          build_menu(child.id)
          concat "</li>\n"
          concat draggable_element(dom_id(child))
          concat drop_receiving_element("droppable_#{dom_id(child)}", 
            :hoverclass => "draghover", 
            :url => receive_drop_admin_pages_path + "?parent_id=#{child.id}", 
            :method => :get,
            :loading => "$('ajax_spinner').src='#{spinner_loc}'; $('reorder_status').show();",
            #:success => "window.location.reload();",
            :success => "$('ajax_spinner').src='#{ok_loc}'",
            :failure => "$('ajax_spinner').src='#{exclamation_loc}'",
            :update => "page-index")
          #, :onDrop => "function(draggable, droppable, overlap){confirm('dropped draggable.id on droppable.id')}"

      end
      concat "</ul>\n"

      # Make this list sortable if more than 1 child.navigatable is listed
      
        concat sortable_element(ul_id,
            :url => reorder_admin_pages_path + "?menu_id=#{(parent_id || 0)}",
            :method => :put,
            :loading => "$('ajax_spinner').src='#{spinner_loc}'; $('reorder_status').show();",
            :success => "$('ajax_spinner').src='#{ok_loc}'",
            :failure => "$('ajax_spinner').src='#{exclamation_loc}'",
            :complete => visual_effect(:fade, "reorder_status", :delay => 1)
          )
      #concat drop_receiving_element(ul_id, :hoverclass => "draghover")
        
      end
    
  end
  
  def build_footer_menu()
    
    concat "<ul id=\"footer_menu_admin\" class=\"sortable\">\n"
      for menu in @footer_menus
        concat "<li id=\"#{dom_id menu}\">"
        concat image_tag("#{move_loc}", :class => "icon handle")
        concat link_to(h(menu.menu_title), [:edit, :admin, (menu.navigatable.blank? ? menu : menu.navigatable)])
        concat "</li>\n"
      end
    concat "</ul>\n"
    concat sortable_element("footer_menu_admin",
          :url => reorder_footer_admin_pages_path,
          :method => :put,
          :loading => "$('ajax_spinner').src='#{spinner_loc}'; $('reorder_status').show();",
          :success => "$('ajax_spinner').src='#{ok_loc}'",
          :failure => "$('ajax_spinner').src='#{exclamation_loc}'",
          :complete => visual_effect(:fade, "reorder_status", :delay => 1)
        )
  end
  
  def menu_form(menu)
    @menu = menu
    concat "<div class=\"page-menu\"><a href=\"#{edit_admin_menu_path(menu.id, :fancy => true)}\" title=\"Manage '#{menu.menu_title}' Placement\" alt=\"Manage Menu Placement\" class=\"fancy-mini-iframe #{menu.status}\">#{menu.status.capitalize}</a></div>"
  end
end
