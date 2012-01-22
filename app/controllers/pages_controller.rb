class PagesController < ApplicationController
  before_filter :get_page_or_404
  after_filter :set_template
  before_filter :authenticate, :only => :show
  unloadable # http://dev.rubyonrails.org/ticket/6001  
  def show
    begin
      @menu = @page.menus.first
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
      # if @page.permalink == "home"
      #   @features = Feature.find(:all, :order => :position)
      # end
      #should refactor the following into scopes and add scoping by scoping
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
          add_breadcrumb @menu.navigatable.title unless @page.permalink == "home" 
        end
      end
      session[:redirect] = request.request_uri if @members
      authorize("Member", "Members") if @members
  end

  def error
    
  end
  
private

  def authenticate
    if @cms_config['modules']['members'] && @page.permission_level != "everyone"
      session[:redirect] = request.request_uri
      authorize(@page.person_groups.collect{|p| p.title}, @page.title)
    end
  end

  def build_tree(current_menu)
    @menus_tmp << current_menu
    @members = true if current_menu.navigatable.permalink == "members"
    if current_menu.parent_id
      parent_menu = Menu.find(current_menu.parent_id)
      build_tree(parent_menu)
    end  
  end

  def get_page_or_404
    render_404 unless @page = Page.find_by_permalink(params[:id])
  end

  def set_template
  
  end
end

