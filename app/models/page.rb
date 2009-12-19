class Page < ActiveRecord::Base
  has_permalink :meta_title
  has_many :images, :as => :viewable, :dependent => :destroy
  has_many :features, :as => :featurable, :dependent => :destroy
  has_many :testimonials, :as => :quotable, :dependent => :destroy
  belongs_to :author, :class_name => 'Person'
  belongs_to :article_category
  validates_presence_of :title, :meta_title, :body
  validates_uniqueness_of :title
  default_scope :order => "parent_id, position"
  named_scope :visible, :conditions => "status = 'visible'"
  named_scope :hidden, :conditions => "status = 'hidden'"

  def to_param
    self.permalink
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

  
end
