class AssetRelation < ActiveRecord::Base
  belongs_to :asset, :class_name => "Asset"
  belongs_to :related_object, :polymorphic => true

  validates_presence_of :asset, :related_object

  # Create a scope so as to position attribute is autoincremented on creation     
  def self.scoped_creation(field, name)
    last_order = self.maximum("asset_relations.position", :conditions => {:field_name => field.to_s})
    last_order ||= 0
    self.with_scope(:create => {:field_name => field.to_s, :name => name.to_s, :position => (last_order+1)}) do
      yield
    end
  end

  # Return the name (used for foot-text of images, for example) for a given asset and field
  def self.name_for_asset(field, asset, related_object)
    asset = Asset.gfind(asset)
    ar = self.find(:first, :conditions => {:field_name => field.to_s, :asset_id => asset.id, :related_object_type => related_object.class.to_s, :related_object_id => related_object.id})
    return asset.name if ar.nil?
    ar.name
  end

  private
    
  # Validate that related object (related_object_type + related_object_id) exist
  def validate
    begin
      raise NameError if related_object_type.constantize.find_by_id(related_object_id).nil?
    rescue NameError
      errors.add(:related_object, I18n.t("ubiquo.media.invalid_related_object_type", :type => related_object_type, :id => related_object_id))
    end
  end
  
end
