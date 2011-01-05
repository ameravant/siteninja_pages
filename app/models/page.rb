class Page < ActiveRecord::Base
  #after_create :make_navigatable
  has_permalink :meta_title
  has_many :images, :as => :viewable, :dependent => :destroy
  has_many :features, :as => :featurable, :dependent => :destroy
  has_many :testimonials, :as => :quotable, :dependent => :destroy
  has_many :menus, :as => :navigatable, :dependent => :destroy
  belongs_to :author, :class_name => 'Person'
  belongs_to :article_category
  belongs_to :column
  validates_presence_of :title, :meta_title, :body
  validates_uniqueness_of :title
  default_scope :order => "parent_id, position"
  named_scope :visible, :conditions => "status = 'visible'"
  named_scope :hidden, :conditions => "status = 'hidden'"
  
  def to_param
    self.permalink
  end
  
  def is_homepage?
    self.permalink == "home"
  end
  
  def name # for model consistency, title is treated as name
    self.title
  end
  
  def description
    self.meta_description
  end
  
  def hidden?
    self.status == 'hidden'
  end
   
  def deleted?
    self.status == 'deleted'
  end
    
  def children
  	Page.find(:all, :conditions => ["parent_id = ?", self.id])
  end
  def parent
    unless self.parent_id.blank?
  	  Page.find(:first, :conditions => ["id = ?", self.parent_id])
  	else
  	  false
  	end
  end
  
  # def make_navigatable
  #     menu = self.menus.new
  #     menu.save
  #     unless page.parent_id.blank?
  #       parent_page = Page.find(page.parent_id)
  #       menu.parent_id = parent_page.menus.first.id
  #     end
  #     menu.position = page.position
  #     menu.footer_pos = page.footer_pos
  #     menu.show_in_footer = page.show_in_footer
  #     menu.can_delete = page.can_delete
  #     menu.status = page.status
  #     menu.save
  #   end
end
