class Admin::PagesController < AdminController
  unloadable # http://dev.rubyonrails.org/ticket/6001
  # cache_sweeper :page_sweeper
  before_filter :authenticate
  before_filter :get_pages, :only => [ :index, :edit, :new, :create ]
  before_filter :build_options, :only => [ :edit, :new, :create ]
  before_filter :find_page, :only => [ :edit, :update, :show ]
  
  # Configure breadcrumbs
  add_breadcrumb "Pages", "admin_pages_path", :only => [ :new, :create, :edit, :update ]
  add_breadcrumb "New", nil, :only => [ :new, :create ]
  
  def index
    add_breadcrumb "Pages"
  end
  
  def edit
    add_breadcrumb @page.name
    @authors = Person.all
    @article_categories = ArticleCategory.active
  end
  
  def show
    @images = @page.images.find :all, :order => "position"
  end
  
  def new
    @page = Page.new
    @authors = Person.all
    @article_categories = ArticleCategory.active
  end
  
  def create
    @page = Page.new params[:page]
    if @page.save
      flash[:notice] = "#{@page.name.titleize} page created."
      redirect_to admin_pages_path
    else
      render :action => "new"
    end
  end
  
  def destroy
    begin
      @page = Page.find_by_permalink_and_can_delete! params[:id], true
      @page.destroy
      flash[:notice] = "#{@page.name} has been deleted."
      respond_to do |wants|
        wants.js
      end
    rescue ActiveRecord::RecordNotFound
      flash[:notice] = 'That page cannot be deleted.'
    end
    # redirect_to admin_pages_path
  end
  
  def update
    @page = Page.find_by_permalink params[:id]
    add_breadcrumb @page.name
    # permalink does not get regenerated
    if @page.update_attributes params[:page]
      flash[:notice] = "#{@page.name} page updated."
      redirect_to admin_pages_path
    else
      render edit_admin_page_path(@page)
    end
  end
  
  def reorder
    params["menu_#{params[:menu_id]}"].each_with_index do |id, position|
      Page.update(id, :position => position + 1)
    end
    render :nothing => true
  end
  
  def restore
    @page = Page.find_by_permalink params[:id]
    @page.update_attributes(:status => 'visible')
    respoadd_dashboard_breadcrumbnd_to :js    
  end
  
  def reorder_footer
    params["footer_menu_admin"].each_with_index do |id, position|
      Page.update(id, :footer_pos => position + 1)
    end
    render :nothing => true
  end
  
  def footer
    @footer_pages = Page.find(:all, :conditions => {:show_in_footer => true}, :order => :footer_pos )
  end
  
  
  private
    
  def get_pages
    @pages = Page.all
    @options_for_parent_id = [['Main menu item','']]
    @options_for_parent_id_level = 0
  end
  
  def find_page
    begin
      @page = Page.find_by_permalink!(params[:id])
    rescue ActiveRecord::RecordNotFound
      redirect_to admin_pages_path
    end
  end
  
  def build_options(parent_id=nil)
    children = @pages.select { |menu_page| menu_page.parent_id == parent_id }
    @options_for_parent_id_level = @options_for_parent_id_level + 1
  
    unless children.empty?
      for child in children
        nbsp_string = '&nbsp;' * (@options_for_parent_id_level * @options_for_parent_id_level) unless @options_for_parent_id_level == 1
        @options_for_parent_id << ["#{nbsp_string}#{child.name}", child.id]
        build_options(child.id)
      end
    end
    
    @options_for_parent_id_level = @options_for_parent_id_level - 1
  end
  
  def authenticate
    unless current_user.has_role(@permissions['pages'])
      flash[:error] = "You do not have access to Pages."
      begin
        redirect_to(:back)
      rescue
        redirect_to("/")
      end
    end
  end
  
end
