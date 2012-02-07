class Admin::PagesController < AdminController
  unloadable # http://dev.rubyonrails.org/ticket/6001
  # cache_sweeper :page_sweeper
  before_filter :authenticate
  before_filter :get_pages, :only => [ :index, :edit, :new, :create, :update ]
  before_filter :build_options, :only => [ :edit, :new, :create, :update ]
  before_filter :get_articles, :only => [ :edit, :new, :create, :update ]
  before_filter :find_page, :only => [ :edit, :update, :show ]

  
  # Configure breadcrumbs
  add_breadcrumb "Pages", "admin_pages_path", :only => [ :new, :create, :edit, :update ]
  add_breadcrumb "New", nil, :only => [ :new, :create ]
  
  def index
    add_breadcrumb "Pages"
  end
  
  def edit
    add_breadcrumb @page.name
    @no_edit = true if @page.permalink == 'page-not-found' or @page.permalink == 'application-error'
  end
  
  def show
    @images = @page.images.find :all, :order => "position"
  end
  
  def new
    @page = Page.new
    @page.column_id = nil
    @menu = Menu.new
  end
  
  def create
    @page = Page.new(params[:page])
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
    @page = Page.new(JSON.parse(@cms_config['site_settings']['preview']))
    @menu = Menu.new()
    @admin = false
    @hide_admin_menu = true
    @page.menus << @menu
    @page.permalink = ""
    @tmplate = @page.template unless @page.template.blank?
    @tmplate.layout_top = @global_template.layout_top if @tmplate.layout_top.blank?
    @tmplate.layout_bottom = @global_template.layout_bottom if @tmplate.layout_bottom.blank?
    @tmplate.article_show = @global_template.article_show if @tmplate.article_show.blank?
    @tmplate.articles_index = @global_template.articles_index if @tmplate.articles_index.blank?
    @tmplate.small_article_for_index = @global_template.small_article_for_index if @tmplate.small_article_for_index.blank?
    @tmplate.medium_article_for_index = @global_template.medium_article_for_index if @tmplate.medium_article_for_index.blank?
    @tmplate.large_article_for_index = @global_template.large_article_for_index if @tmplate.large_article_for_index.blank?
    @side_column_sections = ColumnSection.all(:conditions => {:column_id => @page.column_id, :visible => true})
    @side_column_sections = ColumnSection.all(:conditions => {:column_id => 1, :visible => true}) if @page.column_id.blank?
    @main_column = (@page.main_column_id.blank? ? Column.first(:conditions => {:title => "Default", :column_location => "main_column"}) : Column.find(@page.main_column_id))
    @main_column_sections = ColumnSection.all(:conditions => {:column_id => (@page.main_column_id.blank? ? @main_column.id : @page.main_column_id), :visible => true})
    @images = @page.images
    @footer_pages = Page.find(:all, :conditions => {:show_in_footer => true}, :order => :footer_pos )
    @side_column = @page.column_id
    @foot_text = @page.foot_text
    ops = "person_id = #{@page.author_id}" if @page.author_id
    articles = @page.article_category_id.nil? ? Article.published.find(:all, :conditions => ops) : @page.article_category.articles.published.find(:all, :conditions => ops)
    @testimonial = Testimonial.featured.sort_by(&:rand).first
    @article_categories = ArticleCategory.active
    @article_archive = articles.group_by { |a| [a.published_at.month, a.published_at.year] }
    @article_authors = Person.active.find(:all, :conditions => "articles_count > 0")
    @article_tags = Article.published.tag_counts.sort_by(&:name)
    @recent_articles = articles
    if @page.show_events? and @cms_config['modules']['events']
      @events = Event.future[0..2]
    end
    @home = true if @page.permalink == "home"
    @menus_tmp = []
    build_tree(@menu)
    add_breadcrumb "Home", "/" unless @page.permalink == "home" or @menu.parent_id == 1
    for menu in @menus_tmp.reverse
      unless menu == @menu
        if menu.navigatable_type == "Page"
          add_breadcrumb menu.navigatable.title, "/#{menu.navigatable.permalink}"
        else
          add_breadcrumb menu.navigatable.title, menu.navigatable
        end
      else  
        add_breadcrumb @page.title unless @page.permalink == "home" 
      end
    end
    render 'pages/show'
  end
  
  def post_preview
    @cms_config['site_settings']['preview'] = ActiveSupport::JSON.encode(params[:preview_page])
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
    params["menu_list_#{params[:menu_id]}"].each_with_index do |id, position|
      Menu.update(id, :position => position + 1)
    end
    render :nothing => true
  end
  
  def receive_drop
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
    @options_for_parent_id = [['Main menu item','']]
    @options_for_parent_id_level = 0
  end
  
  def find_page
    begin
      @page = Page.find_by_permalink!(params[:id])
      @menu = @page.menus.first
    rescue ActiveRecord::RecordNotFound
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
