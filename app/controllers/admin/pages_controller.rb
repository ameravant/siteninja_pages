class Admin::PagesController < AdminController
  unloadable # http://dev.rubyonrails.org/ticket/6001
  # cache_sweeper :page_sweeper
  before_filter :authenticate
  before_filter :get_pages, :only => [ :edit, :new, :create, :update ]
  before_filter :build_options, :only => [ :edit, :new, :create, :update ]
  before_filter :get_articles, :only => [ :edit, :new, :create, :update ]
  before_filter :find_page, :only => [ :edit, :update, :show ]
  
  # Configure breadcrumbs
  add_breadcrumb "Pages", "admin_pages_path", :only => [ :new, :create, :edit, :update ]
  add_breadcrumb "New", nil, :only => [ :new, :create ]
  
  def index
    add_breadcrumb "Pages"
    if params[:batch]
      template_id = params[:template_id] ? params[:template_id].to_i : nil
      main_column_id = params[:main_column_id] ? params[:main_column_id].to_i : nil
      if params[:page_ids]
        for p in params[:page_ids]
          page = Page.find_by_id(p.to_i)
          logger.info(page.id)
          page.template_id = template_id
          page.main_column_id = main_column_id
          page.save      
        end
        #redirect_to(admin_pages_path)
        flash[:notice] = "Batch update completed."
      end
    end
  end                
  
  def ajax_index
    @templates = Template.all
    @layouts = Column.all(:conditions => {:column_location => "main_column"})
    @admin = false
    @hide_admin_menu = true
    render :layout => false
  end
  
  def ajax_page_for_list
    @admin = false
    @hide_admin_menu = true
    render :layout => false
  end
  
  def edit
    add_breadcrumb @page.name
    @no_edit = true if @page.permalink == 'page-not-found' or @page.permalink == 'application-error'
  end
  
  def show
    @images = @page.images.find :all, :order => "position"
  end
  
  def batch
    if params[:page_ids]
      for p in params[:page_ids]
        page = Page.find(p)
        page.template_id = params[:template_id] if params[:template_id]
        page.main_column_id = params[:main_column_id] if params[:main_column_id]
        page.save      
      end
      #redirect_to(admin_pages_path)
      flash[:notice] = "Batch update completed."
    end
  end
  
  def new
    @main_column = Column.find_by_title("Default")
    if @main_column.blank?
      @main_column = Column.find_by_title("Default Page Layout")
    end
    @page = Page.new
    @page.column_id = nil
    @page.main_column_id = Column.find_by_title("Default").id
    @page.automatically_embed_videos_and_images = false if @cms_config['site_settings']['set_automatically_embed_to_false']
    @menu = Menu.new
  end
  
  def create
    @page = Page.new(params[:page])
    @main_column = Column.find_by_id(@page.main_column_id)
    @menu = Menu.new(params[:menu])
    add_person_groups
    if @page.save
      @menu = @page.menus.new params[:menu]
      @menu.save
      flash[:notice] = "#{@page.name.titleize} page created."
      redirect_to admin_pages_path
    else
      render :action => "new"
    end
  end
  
  def preview
    if !params[:reload]
      @page = Page.new(JSON.parse(@cms_config['site_settings']['preview_page']))
      @menu = Menu.new()
      if !@page.permalink.blank?
        @menu = Page.find_by_permalink(@page.permalink).menus.first
      end
      @admin = false
      @hide_admin_menu = true
      @page.menus << @menu
      
      @images = @page.permalink.empty? ? [] : Page.find_by_permalink(@page.permalink).images
      
      get_page_defaults(@page)
      
      @owner = @page
    end
  end

  def ajax_preview
    @page = Page.new(JSON.parse(@cms_config['site_settings']['preview_page']))
    @menu = Menu.new()
    @admin = false
    @hide_admin_menu = true
    @page.menus << @menu

    @images = @page.permalink.empty? ? [] : Page.find_by_permalink(@page.permalink).images

    get_page_defaults(@page)
    
    @owner = @page
    
    render :layout => false
  end
  
  def post_preview
    @cms_config['site_settings']['preview_page'] = ActiveSupport::JSON.encode(params[:preview_page])
    File.open(@cms_path, 'w') { |f| YAML.dump(@cms_config, f) }
  end
  
  
  def destroy
    # begin
    #       @page = Page.find_by_permalink_and_can_delete! params[:id], true
    #       @page.menus.first.destroy
    #       @page.destroy
    #       flash[:notice] = "#{@page.name} has been deleted."
    #       respond_to do |wants|
    #         wants.js
    #       end
    #     rescue ActiveRecord::RecordNotFound
    #       flash[:notice] = 'That page cannot be deleted.'
    #     end
    #     # redirect_to admin_pages_path
  end
  
  def update
    @page = Page.find_by_permalink params[:id]
    @menu = @page.menus.first
    add_breadcrumb @page.name
    # permalink does not get regenerated
    add_person_groups
    if @page.update_attributes params[:page] and @menu.update_attributes params[:menu]
      flash[:notice] = "#{@page.name} page updated."
      redirect_to admin_pages_path
    else
      render :action => "edit", :id => @page
    end
  end
  
  def reorder
    @templates = Template.all
    @layouts = Column.all(:conditions => {:column_location => "main_column"})
    params["menu_list_#{params[:menu_id]}"].each_with_index do |id, position|
      Menu.update(id, :position => position + 1)
    end
    render :nothing => true
  end
  
  def receive_drop
    @templates = Template.all
    @layouts = Column.all(:conditions => {:column_location => "main_column"})
    menu_id = params[:id].to_s.gsub("menu_", "").to_i
    menu = Menu.find(menu_id)
    children = Menu.find(:all, :conditions => {:parent_id => params[:parent_id]})
    for child in children
      child.update_attributes(:position => child.position + 1)
    end
    menu.update_attributes(:parent_id => params[:parent_id], :position => 1) unless params[:parent_id].to_i == menu.id.to_i or menu.id == 1
    @menus = Menu.all
    render :action => :index, :layout => false
  end
  
  def reorder_footer
    params["footer_menu_admin"].each_with_index do |id, position|
      Menu.update(id, :footer_pos => position + 1)
    end
    render :nothing => true
  end
  
  def footer
    @footer_menus = Menu.find(:all, :conditions => {:show_in_footer => true}, :order => :footer_pos )
  end
  
  
  private
    
  def get_pages
    @pages = Page.all
    @menus = Menu.all
    @templates = Template.all
    @layouts = Column.all(:conditions => {:column_location => "main_column"})
    @options_for_parent_id = [['Main menu item','']]
    @options_for_parent_id_level = 0
  end
  
  def find_page
    begin
      @page = Page.find_by_permalink!(params[:id])
      if @page.main_column_id.blank? or Column.find_by_id(@page.main_column_id).blank?
        @main_column = Column.find_by_title("Default")
        if @main_column.blank?
          @main_column = Column.find_by_title("Default Page Layout")
        end
        @page.main_column_id = @main_column.id
      else
        @main_column = Column.find(@page.main_column_id)
      end
      @menu = @page.menus.first
    rescue Exception => exc
      redirect_to admin_pages_path
    end
  end
  
  def build_options(parent_id=nil)
    children = @menus.select { |menu| menu.parent_id == parent_id }
    @options_for_parent_id_level = @options_for_parent_id_level + 1
    unless children.empty?
      for child in children
        nbsp_string = '&nbsp;' * (@options_for_parent_id_level * @options_for_parent_id_level) unless @options_for_parent_id_level == 1 
        if params[:id]
          @options_for_parent_id << ["#{nbsp_string}#{child.menu_title}", child.id] unless child.navigatable_id == Page.find_by_permalink(params[:id]).id
        else
          @options_for_parent_id << ["#{nbsp_string}#{child.menu_title}", child.id] 
        end
        build_options(child.id)
      end
    end
    @options_for_parent_id_level = @options_for_parent_id_level - 1
  end
  
  
  def build_tree(current_menu)
    @menus_tmp << current_menu
    if current_menu.parent_id
      parent_menu = Menu.find(current_menu.parent_id)
      build_tree(parent_menu)
    end  
  end
  
  def get_articles
    @authors = Person.all(:conditions => ["articles_count > ?", 0])
    @article_categories = ArticleCategory.active
    @templates = Template.all
    @side_columns = Column.all(:conditions => {:column_location => "side_column"})
    @main_columns = Column.all(:conditions => {:column_location => "main_column"})
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
  def add_person_groups
    if @cms_config['modules']['members']
      if params[:page][:permission_level] == "except those checked"
        params[:page][:person_group_ids] = PersonGroup.is_role.collect(&:id).delete_if{|c| params[:page][:person_group_ids].include?(c.to_s)}
      elsif params[:page][:permission_level] == "administrators"
        params[:page][:person_group_ids] = [1]
      elsif params[:page][:permission_level] == "everyone"
        params[:page][:person_group_ids] = PersonGroup.is_role.collect(&:id)
      end        
    end
  end
end
