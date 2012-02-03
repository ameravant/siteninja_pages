class PagesController < ApplicationController
  before_filter :get_page_or_404
  after_filter :set_template
  before_filter :authenticate, :only => :show
  unloadable # http://dev.rubyonrails.org/ticket/6001  
  def show
    get_page_defaults(@page)
  end

  def error
    @page = Page.find_by_permalink("application-error") if @page.blank?
  end
  
private

  def authenticate
    if @cms_config['modules']['members'] && @page.permission_level != "everyone"
      session[:redirect] = request.request_uri
      authorize(@page.person_groups.collect{|p| p.title}, @page.title)
    end
  end


  def get_page_or_404
    render_404 unless @page = Page.find_by_permalink(params[:id])
  end

  def set_template
  
  end
end

