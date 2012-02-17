module PagesHelper
  def page_path(page)
    "/#{page.permalink}"
  end
end
