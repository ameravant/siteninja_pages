resources :pages, :member => { :comment => :post }, :has_many => [:comments, :images, :testimonials]

namespace :admin do |admin|
  admin.resources :pages, :collection => { :reorder => :put, :receive_drop => :get, :batch => :get, :footer => :get, :reorder_footer => :put, :preview => :get, :post_preview => :put, :ajax_preview => :get }, :has_many => [ :comments ] do |page|
    page.resources :features, :menus
    page.resources :images, :member => { :reorder => :put }, :collection => { :reorder => :put, :add_multiple => :get }
    page.resources :testimonials, :collection => { :reorder => :put }
  end
end

root :controller => "pages", :action => "show", :id => "home"

connect '/tinymce/:action', :controller => "tinymce"
connect ':id', :controller => "pages", :action => "show"
