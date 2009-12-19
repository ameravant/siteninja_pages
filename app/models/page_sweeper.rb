class PageSweeper < ActionController::Caching::Sweeper
  observe Page

  def after_save(page)
    expire_cache_for(page)
  end

  def after_create(page)
    expire_cache_for(page)
  end

  def after_destroy(page)
    expire_cache_for(page)
  end

  private

  def expire_cache_for(record)
    expire_page "/index.html"
    for p in Page.all
      expire_page "/#{p.permalink}"
    end
  end

end