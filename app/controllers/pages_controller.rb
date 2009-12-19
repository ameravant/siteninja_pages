class PagesController < ApplicationController
  unloadable # http://dev.rubyonrails.org/ticket/6001
  
  def show
    begin
      @page = Page.find_by_permalink! params[:id]
      @images = @page.images
      @footer_pages = Page.find(:all, :conditions => {:show_in_footer => true}, :order => :footer_pos )
      if @page.permalink == "home"
        @features = Feature.find(:all, :order => :position)
      end
      #should refactor the following into scopes and add scoping by scoping
      ops = "person_id = #{@page.author_id}" if @page.author_id
      articles = @page.article_category_id.nil? ? Article.published.find(:all, :conditions => ops) : @page.article_category.articles.published.find(:all, :conditions => ops)
      @testimonial = Testimonial.featured.sort_by(&:rand).first
      @article_categories = ArticleCategory.active
      @article_archive = articles.group_by { |a| [a.published_at.month, a.published_at.year] }
      @article_authors = Person.active.find(:all, :conditions => "articles_count > 0")
      @article_tags = Article.published.tag_counts.sort_by(&:name)
      @recent_articles = articles[0...5]
      if @page.show_events? and @cms_config['modules']['events']
        @events = Event.future[0..2]
      end
    rescue ActiveRecord::RecordNotFound
      redirect_to '/404.html'
    end
    @pages_tmp = []
      build_tree(@page)
      add_breadcrumb "Home", "/" unless @page.permalink == "home" or @page.parent_id == 1
      for page in @pages_tmp.reverse
        unless page == @page
          add_breadcrumb page.name, page_path(page)
        else  
          add_breadcrumb page.name unless @page.permalink == "home" 
        end
      end
      session[:redirect] = request.request_uri if @members
      authorize("Member", "Members") if @members
  end

private

 def build_tree(current_page)
  @pages_tmp << current_page
  @members = true if current_page.permalink == "members"
  if current_page.parent
    parent_page = current_page.parent
    build_tree(parent_page)
  end  
end



end
