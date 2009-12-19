resources :pages, :has_many => [:images, :testimonials]

namespace :admin do |admin|
  admin.resources :pages, :collection => { :reorder => :put, :footer => :get, :reorder_footer => :put } do |page|
    page.resources :features
    page.resources :images, :member => { :reorder => :put }, :collection => { :reorder => :put }
    page.resources :testimonials, :collection => { :reorder => :put }
  end
end

root :controller => "pages", :action => "show", :id => "home"

connect '/tinymce/:action', :controller => "tinymce"
connect ':id', :controller => "pages", :action => "show"
