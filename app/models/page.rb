class Page < ActiveRecord::Base
  #after_create :make_navigatable
  #establish_connection(ActiveRecord::Base.configurations["production"])
  has_permalink :meta_title
  has_many :comments, :as => :commentable
  has_many :images, :as => :viewable, :dependent => :destroy
  has_many :activities, :as => :loggable, :dependent => :destroy
  has_many :features, :as => :featurable, :dependent => :destroy
  has_many :testimonials, :as => :quotable, :dependent => :destroy
  has_many :menus, :as => :navigatable, :dependent => :destroy
  has_many :assets, :as => :attachable, :dependent => :destroy
  has_many :ratings, :as => :rateable, :dependent => :destroy
  belongs_to :template
  belongs_to :author, :class_name => 'Person'
  belongs_to :article_category
  belongs_to :column
  belongs_to :page_layout, :class_name => "Column", :foreign_key => :main_column_id
  validates_presence_of :title, :meta_title
  validates_uniqueness_of :title
  default_scope :order => "parent_id, position"
  named_scope :visible, :conditions => "status = 'visible'"
  named_scope :hidden, :conditions => "status = 'hidden'"
  accepts_nested_attributes_for :images
  has_and_belongs_to_many :person_groups
  
  
  def to_param
    self.permalink
  end
  
  def is_homepage?
    self.permalink == "home"
  end
  
  def self.build_filter_conditions(template_id, main_column_id, side_column_id)
    cond = []
    cond << send(:sanitize_sql_array, ["template_id = ?", template_id]) if template_id
    cond << send(:sanitize_sql_array, ["main_column_id = ? ", main_column_id]) if main_column_id
    cond << send(:sanitize_sql_array, ["side_column_id = ? ", side_column_id]) if side_column_id
    cond.join(" and ")
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
