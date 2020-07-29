class PagesController < ApplicationController
  before_filter :get_page_or_404
  after_filter :set_template
  before_filter :authenticate, :only => :show
  unloadable # http://dev.rubyonrails.org/ticket/6001  
  def show
    #expires_in 60.minutes, :public => true
    get_page_defaults(@page)
    @edit_path = edit_admin_page_path(@page, :params => {:redirect_path => request.request_uri})#[:edit, :admin, @page, ]
    @edit_type = "Page"
    if params[:edit_mode]
      session[:edit_mode] = params[:edit_mode]
      redirect_to session[:redirect_path]
    end    
    #session[:redirect_path] = @page.menus.first.url
  end
  
  def index
    get_page_defaults(@page)
    render 'pages/show'
  end
  
  def error
    @page = Page.find_by_permalink("application-error") if @page.blank?
  end
  
  def sitemap
    
  end
private

  def authenticate
    if @cms_config['modules']['members'] && @page.permission_level != "everyone"
      session[:redirect] = request.request_uri
      authorize(@page.person_groups.collect{|p| p.title}, @page.title)
    end
  end

  def get_page_or_404
    if request.request_uri.include?("/pages/")
      redirect_to(request.request_uri.gsub("/pages/", "/"), :status => 301)
    else
      render_404 unless @page = Page.find_by_permalink(params[:id])
    end
  end

  def set_template
  
  end
  

end

