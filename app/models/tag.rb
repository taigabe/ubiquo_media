class Tag < ActiveRecord::Base

  has_many :asset_tags
  has_many :assets, :through => :asset_tags
  before_validation :urilize_name
  
  validates_presence_of :name
  validates_uniqueness_of :name
  
  # Generic find (ID, key or record)
  def self.find_by(something, options={})
    case something
    when Fixnum
      find_by_id(something, options)
    when String, Symbol
      find_by_name(something.to_s, options)
    when Tag
      something
    else
      nil
    end
  end
    
  # Take a string separated with commas and create the tags. Tags name
  # are urilized before saving (as tags are likely to be part of URLs)
  def self.create_for(tags)
    urilized_tags = [tags].flatten.map { |t| t.split(",").map(&:strip).map(&:urilize) }
    urilized_tags.flatten.uniq.map do |tag|
      found = find_by(tag)
      (found = create(:name => tag.strip)) if found.nil?
      found
    end
  end

  # Return only tags that have associated assets
  def self.find_for_assets
    Tag.find(:all).reject { |tag| tag.assets.empty? }
  end
  
  private
  
  # Urilize the name of a tag if it is set 
  def urilize_name
    self.name = self.name.urilize if self.name
  end
  
end
