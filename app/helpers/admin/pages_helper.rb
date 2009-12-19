module Admin::PagesHelper

  def build_menu(parent_id=nil)
    children = @pages.select { |menu_page| menu_page.parent_id == parent_id }
    ul_id = "menu_#{parent_id || '0'}"
    unless children.empty?
      concat "<ul id=\"#{ul_id}\" class=\"sortable\">\n"

      # Output the list elements for these children, and recursively
      # call build_menu for their children.
      for child in children
        concat "<li id=\"#{dom_id child}\" style=\"border-top: #ccc 1px solid; \">" + '<div class="page-title">'
        concat image_tag("#{move_loc}", :class => "icon handle") + ' ' if children.size > 1
        concat link_to(h(child.title), edit_admin_page_path(child), :class => child.hidden? ? 'gray' : nil)
        concat ' ' + content_tag('span', '&mdash; hidden from menus', :class => ' small gray') if child.status == 'hidden'
        concat ' &mdash; ' + link_to("Manage Homepage Features", admin_features_path) if (child.permalink == "home")
        concat '</div><div class="page-options">'
          if child.images_count > 0
            if child.features_count > 0
              concat defeature_icon(child, "/admin/pages/#{child.to_param}/features/1", child.title, "inline")
              concat feature_icon(child, [:admin, child, :features], child.title, "none")
            else
              concat feature_icon(child, [:admin, child, :features], child.title, "inline")
              concat defeature_icon(child, "/admin/pages/#{child.to_param}/features/1", child.title, "none")
            end
          else
            concat disabled_feature_icon(child, [:new, :admin, child, :feature], child.title)
          end
        concat ' ' + icon("Write", edit_admin_page_path(child))
        #Check page is allowed to be deleted and provide icon to allow it
        if child.can_delete
          concat ' ' + trash_icon(child, admin_page_path(child), "#{child.title}")
        else
          concat ' ' + "<div style='width: 16px; height: 16px; float: right; margin-left: 4px;'></div>"
        end
        if @cms_config['features']['testimonials']
        concat '</div><div class="page-testimonials">'
        concat icon("Bubble 1", [:admin, child, :testimonials]) + ' ' + link_to(child.testimonials_count, [:admin, child, :testimonials])
        end
        concat '</div><div class="page-images">'
        concat icon("Picture", [:admin, child, :images]) + ' ' + link_to(child.images_count, [:admin, child, :images])
        concat "</div>" + clear
        build_menu(child.id)
        concat "</li>\n"
      end
      concat "</ul>\n"

      # Make this list sortable if more than 1 child is listed
      
        concat sortable_element(ul_id,
          :url => reorder_admin_pages_path + "?menu_id=#{(parent_id || 0)}",
          :method => :put,
          :loading => "$('ajax_spinner').src='#{spinner_loc}'; $('reorder_status').show();",
          :success => "$('ajax_spinner').src='#{ok_loc}'",
          :failure => "$('ajax_spinner').src='#{exclamation_loc}'",
          :complete => visual_effect(:fade, "reorder_status", :delay => 1)
        )
      end
    
  end
  
  def build_footer_menu()
    
    concat "<ul id=\"footer_menu_admin\" class=\"sortable\">\n"
      for page in @footer_pages
        concat "<li id=\"#{dom_id page}\">"
        concat image_tag("#{move_loc}", :class => "icon handle")
        concat link_to(h(page.title), edit_admin_page_path(page))
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
end
