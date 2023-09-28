class Admin::PagesController < AdminController
  unloadable # http://dev.rubyonrails.org/ticket/6001
  # cache_sweeper :page_sweeper
  before_filter :authenticate
  before_filter :get_pages, :only => [ :edit, :new, :create, :update ]
  before_filter :build_options, :only => [ :edit, :new, :create, :update ]
  before_filter :get_articles, :only => [ :edit, :new, :create, :update ]
  before_filter :find_page, :only => [ :edit, :update, :show ]
  
  # Configure breadcrumbs
  add_breadcrumb "Pages", "admin_pages_path", :only => [ :new, :create, :edit, :update, :footer ]
  add_breadcrumb "New", nil, :only => [ :new, :create ]
  
  require 'fastercsv'
  require 'csv'

  def save_render
    page = Page.find_by_id(params[:page][:id])
    page.update_attributes(:rendered_body => params[:page][:rendered_body])
    if page == Page.all(:order => "id").last
      redirect_to ("/admin/pages?csv=true")
    else
      next_page = Page.all(:order => "id", :conditions => ['id > ?', page.id]).first
      redirect_to("/admin/pages/#{next_page.permalink}?render=true")
    end
  end

  def index
    if params[:csv]
      redirect_to("/admin/pages.csv")
    else
      if params[:clear_cache]
        expire_fragment(:controller => 'admin/pages', :action => 'ajax_index', :action_suffix => 'all_pages')
        expire_fragment("dropdown-menus-#{$CURRENT_ACCOUNT.id}")
        expire_fragment("expandable-menus-#{$CURRENT_ACCOUNT.id}")
        flash[:notice] = "Menu fragment cache cleared."
        redirect_to admin_pages_path
      end
      add_breadcrumb "Pages"
      #session[:redirect_path] = admin_pages_path
      @templates = Template.all
      @master_layouts = Column.all(:conditions => {:column_location => "master"})
      @layouts = Column.all(:conditions => {:column_location => "main_column"})
      @side_columns = Column.all(:conditions => {:column_location => "side_column"})

      if params[:batch]
        template_id = params[:templte_id] ? params[:templte_id] : nil
        main_column_id = params[:main_column_id] ? params[:main_column_id] : nil
        master_layout_id = params[:master_layout_id] ? params[:master_layout_id] : nil

        if params[:page_ids]
          for p in params[:page_ids]
            page = Page.first(:conditions => {:id => p})
            logger.info("params page id = #{p}")
            logger.info("page id = #{page.id}")
            page.template_id = template_id if template_id != ""
            page.main_column_id = main_column_id if main_column_id != ""
            page.master_layout_id = master_layout_id if master_layout_id != ""
            page.save 

          end
          #redirect_to(admin_pages_path)
          flash[:notice] = "Batch update completed."
        end
      end
      if params[:default_view]
        if params[:default_view] == "paginate"
          session[:page_index] = "paginate"
          @cms_config["site_settings"]["paginate_page_index"] = true
        elsif params[:default_view] == "tree"
          session[:page_index] = "tree"
          @cms_config["site_settings"]["paginate_page_index"] = false
        end
        flash[:notice] = "Default view updated successfully."
        File.open(@cms_path, 'w') { |f| YAML.dump(@cms_config, f) }
        redirect_to(admin_pages_path)
      end
      if (@cms_config['site_settings']['paginate_page_index'] or params[:paginate_page_index] or session[:page_index] == "paginate") and (params[:paginate_page_index] != "false")
        session[:page_index] = "paginate"
        @paginate_page_index = true
        if params[:letter]
          pages = Page.all(:conditions => ["title like ?", "#{params[:letter]}%"])
        else
          params[:q].blank? ? pages = Page.all(:order => "title") : pages = Page.find(:all, :conditions => ["title like ? or meta_title like ?", "%#{params[:q]}%","%#{params[:q]}%"], :order => "title")
        end
        @pages = pages.paginate(:page => params[:page], :per_page => 15)
        if params[:filter]
          template_id = !params[:template_id].blank? ? params[:template_id] : nil
          main_column_id = !params[:main_column_id].blank? ? params[:main_column_id] : nil
          side_column_id = !params[:side_column_id].blank? ? params[:side_column_id] : nil
          @pages = Page.all(:conditions => Page.build_filter_conditions(template_id, main_column_id, side_column_id)).paginate(:page => params[:page], :per_page => 100)
        end
      elsif params[:paginate_page_index] == "false"
        session[:page_index] = "tree"
        @paginate_page_index = false
      end

      # Export CSV
      respond_to do |wants|
        require 'fastercsv'
        @all_pages = Page.all
        wants.html
        wants.csv do
          @outfile = "pages_" + Time.now.strftime("%Y-%m-%d-%H-%M-%S") + ".csv"
          csv_data = FasterCSV.generate do |csv|
            csv << ["ID", "Title", "Content", "Excerpt", "Date", "Post Type", "Permalink", "Image URL", "Image Title", "Image Caption", "Image Description", "Image Alt Text", "Image Featured", "Attachment URL", "Status", "Slug", "Comment Status", "Ping Status", "Post Modified Date"]#, "images_count", "assets_count", "features_count"]
            @all_pages.each do |page|
              page_body = page.rendered_body.blank? ? page.body : page.rendered_body.gsub('data-src', 'src')
              i = Image.first(:conditions => {:viewable_id => page.id, :viewable_type => "Page", :show_as_cover_image => true})
              i = Image.first(:conditions => {:viewable_id => page.id, :viewable_type => "Page", :show_in_image_box => true}) if i.blank?
              i = Image.first(:conditions => {:viewable_id => page.id, :viewable_type => "Page", :show_in_slideshow => true}) if i.blank?
              if !i.blank?
                image_url = i.image(:original)
                image_title = i.title
                image_caption = i.caption
                image_description = i.description
              else
                image_url = ""
                image_title = ""
                image_caption = ""
                image_description = ""
              end
              images = Image.all(:conditions => {:viewable_id => page.id, :viewable_type => "Page"}, :order => "show_as_cover_image, position asc")
              status = page.status == "visible" ? "publish" : "draft"
              csv << [page.id, page.title, page_body, page.meta_description, page.created_at.strftime("%Y-%m-%d %H:%M:%S"), "page", page_url(page), images.collect{|i| i.image(:original)}.join(','), images.collect{|i| i.title}.join(','), images.collect{|i| i.caption}.join(','), images.collect{|i| i.description}.join(','), images.collect{|i| i.title}.join(','), image_url, "", status, page.permalink, "closed", "closed", page.updated_at.strftime("%Y-%m-%d %H:%M:%S")]
            end
          end
          send_data csv_data,
          :type => 'text/csv; charset=iso-8859-1; header=present',
          :disposition => "attachment; filename=#{@outfile}"
          flash[:notice] = "Export complete!"
        end
      end
    end
  end
  
  def ajax_index
    @templates = Template.all
    @layouts = Column.all(:conditions => {:column_location => "main_column"})
    @master_layouts = Column.all(:conditions => {:column_location => "master"})
    @admin = false
    @hide_admin_menu = true
    render :layout => false
  end

  def insert_link
    if params[:q]
      @pages = Page.find(:all, :conditions => ["title like ? or meta_title like ?", "%#{params[:q]}%","%#{params[:q]}%"], :order => "title")
      @events = Event.find(:all, :conditions => ["name like ?", "%#{params[:q]}%"], :order => "name")
      @links = Link.find(:all, :conditions => ["title like ?", "%#{params[:q]}%",], :order => "title")
      @articles = Article.find(:all, :conditions => ["title like ?", "%#{params[:q]}%"], :order => "title")
      @galleries = Gallery.find(:all, :conditions => ["title like ?", "%#{params[:q]}%"], :order => "title")
    end
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
        logger.info("params page id = #{p}")
        logger.info("page id = #{page.id}")
        page.template_id = params[:template_id] if params[:template_id]
        page.main_column_id = params[:main_column_id] if params[:main_column_id]
        master_layout_id = params[:master_layout_id] if params[:master_layout_id]
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
    if params[:duplicate_id] and Page.find(params[:duplicate_id])
      @page = Page.find_by_id(params[:duplicate_id]).clone
      @page.title = "#{@page.title} (Copy)"
      @page.meta_title = "#{@page.meta_title} (Copy)"
      @page.permalink = ""
    end
    @menu = Menu.new
  end
  
  def create
    @page = Page.new(params[:page])
    @main_column = Column.find_by_id(@page.main_column_id)
    @menu = Menu.new(params[:menu])
    add_person_groups
    expire_fragment(:controller => 'admin/pages', :action => 'ajax_index', :action_suffix => 'all_pages')
    expire_fragment("dropdown-menus-#{$CURRENT_ACCOUNT.id}")
    expire_fragment("expandable-menus-#{$CURRENT_ACCOUNT.id}")
    if @page.save
      @menu = @page.menus.new params[:menu]
      @menu.save
      flash[:notice] = "#{@page.name.titleize} page created."
      log_activity("Created \"#{@page.name.titleize}\"")
      session[:cache] = true
      redirect_to !params[:redirect_path].blank? ? params[:redirect_path] : admin_pages_path
    else
      render :action => "new"
    end
  end
  
  def preview
    if !params[:reload]
      @page = Page.new(JSON.parse(@settings.page_preview))
      @menu = Menu.new()
      if !@page.permalink.blank?
        @menu = Page.find_by_permalink(@page.permalink).menus.first
      else
        @menu = Page.find_by_permalink("home").menus.first
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
    @page = Page.new(JSON.parse(@settings.page_preview))
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
    @settings.update_attributes(:page_preview => ActiveSupport::JSON.encode(params[:preview_page]))
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
    if params[:page][:title] != @page.title or (params[:menu][:permalink] and params[:page][:permalink] != @page.permalink)
      expire_fragment(:controller => 'admin/pages', :action => 'ajax_index', :action_suffix => 'all_pages')
      expire_fragment("dropdown-menus-#{$CURRENT_ACCOUNT.id}")
      expire_fragment("expandable-menus-#{$CURRENT_ACCOUNT.id}")
    end
    add_person_groups
    if @page.update_attributes params[:page] and @menu.update_attributes params[:menu]
      flash[:notice] = "#{@page.name} page updated."
      log_activity("Updated \"#{@page.name.titleize}\"")
      session[:cache] = true
      redirect_to !params[:redirect_path].blank? ? params[:redirect_path] : admin_pages_path
    else
      render :action => "edit", :id => @page
    end
  end
  
  def reorder
    @templates = Template.all
    @layouts = Column.all(:conditions => {:column_location => "main_column"})
    expire_fragment(:controller => 'admin/pages', :action => 'ajax_index', :action_suffix => 'all_pages')
    expire_fragment("dropdown-menus-#{$CURRENT_ACCOUNT.id}")
    expire_fragment("expandable-menus-#{$CURRENT_ACCOUNT.id}")
    params["menu_list_#{params[:menu_id]}"].each_with_index do |id, position|
      Menu.update(id, :position => position + 1)
    end
    render :nothing => true
  end
  
  def receive_drop
    expire_fragment(:controller => 'admin/pages', :action => 'ajax_index', :action_suffix => 'all_pages')
    expire_fragment("dropdown-menus-#{$CURRENT_ACCOUNT.id}")
    expire_fragment("expandable-menus-#{$CURRENT_ACCOUNT.id}")
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
    add_breadcrumb "Footer Menu Organization"
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
    @master_layouts = Column.all(:conditions => {:column_location => "master"})
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
  
  def log_activity(description)
    add_activity(controller_name.classify, @page.id, description)
  end
  
  def add_person_groups
    if @cms_config['modules']['members']
      if params[:page][:permission_level] == "except those checked"
        params[:page][:person_group_ids] = PersonGroup.is_role.collect(&:id).delete_if{|c| params[:page][:person_group_ids].include?(c.to_s)} if params[:page][:person_group_ids]
      elsif params[:page][:permission_level] == "administrators"
        params[:page][:person_group_ids] = [1]
      elsif params[:page][:permission_level] == "everyone"
        params[:page][:person_group_ids] = PersonGroup.is_role.collect(&:id)
      end        
    end
  end
end
