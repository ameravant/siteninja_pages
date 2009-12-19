class TinymceController < ApplicationController
  unloadable # http://dev.rubyonrails.org/ticket/6001
  layout nil

  def generate_images_list
    @tinymce_assets = Asset.all
    @tinymce_assets.reject! { |asset| asset.file_file_name !~ /(gif|png|jpeg|jpg)/ }
  end

  def generate_links_list
    @tinymce_assets = Asset.all
    @tinymce_assets.reject! { |asset| asset.file_file_name =~ /(gif|png|jpeg|jpg)/ }
  end

end