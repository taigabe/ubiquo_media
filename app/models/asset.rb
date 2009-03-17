# An asset is a resource with name, description and one associated
# file. Optionally assets can be categorized unser some asset tags.
class Asset < ActiveRecord::Base
  belongs_to :asset_type
  has_many :asset_tags, :dependent => :destroy
  has_many :tags, :through => :asset_tags

  validates_presence_of :name, :asset_type_id, :type
  validate :check_tags
  after_save :set_asset_tags

  attr_accessor :tags_string

  # Generic find (ID, key or record)
  def self.gfind(something, options={})
    case something
    when Fixnum
      find_by_id(something, options)
    when String, Symbol
      find_by_name(something.to_s, options)
    when Asset
      something
    else
      nil
    end
  end

  # Virtual attribute: returns tags for this asset as a comma-separated string
  def tags_string
    (@create_tags || self.tags).map(&:name).join(", ")
  end

  # Virtual attribute: set tags for this asset as a comma-separated string
  def tags_string=(value)
    @create_tags = Tag.create_for(value)
  end

  # filters:

  #   :tag: String to search in tag name
  #   :type: ID of AssetType separated by commas
  #   :text: String to search in asset name and description
  #
  # options: find_options
  def self.filtered_search(filters = {}, options = {})
    filter_tag = filters[:tag].blank? ? {} :
    {:find => {:include => :tags, :conditions => ["tags.name ILIKE ?", "%#{filters[:tag]}%"]}}
    filter_type = if filters[:type]
      types_id = filters[:type].to_s.split(",").map(&:to_i)
      {:find => {:conditions => ["assets.asset_type_id IN (?)", types_id]}}
    else {}
    end
    filter_text = unless filters[:text].blank?
      args = ["%#{filters[:text]}%"] * 2
      condition = "assets.name ILIKE ? OR assets.description ILIKE ?"
      {:find => {:include => :tags, :conditions => [condition] + args}}
    else {}
    end
    filter_visibility = unless filters[:visibility].blank?
      {:find => {:conditions => ["assets.type = ?", "asset_#{filters[:visibility]}".classify]}}
    else {}
    end
    filter_create_start = if filters[:created_start]
      {:find => {:conditions => ["assets.created_at >= ?", filters[:created_start]]}}
    else {}
    end      
    filter_create_end = if filters[:created_end]
      {:find => {:conditions => ["assets.created_at <= ?", filters[:created_end]]}}
    else {}
    end      
    
    with_scope(filter_text) do
      with_scope(filter_type) do
        with_scope(filter_visibility) do
          with_scope(filter_tag) do
            with_scope(filter_create_start) do
              with_scope(filter_create_end) do  
                with_scope(:find => options) do
                  Asset.find(:all)
                end
              end
            end
          end
        end
      end
    end
  end

  private

  # Read current tags_string value and get Tag instances in accordance.
  # This instances will be existing or new records.
  # Fail if any generated tag is invalid
  def check_tags
    if @create_tags && @create_tags.detect { |tag| !tag.valid? }
      self.errors.add(:tags_string, t('ubiquo.media.invalid'))
    end
  end

  # Save the asset_tags many-to-many relation
  def set_asset_tags
    return unless @create_tags
    self.asset_tags.delete_all
    self.tags << @create_tags
    self.tags.reload
    @create_tags = nil
  end
end
