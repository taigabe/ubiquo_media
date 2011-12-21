class AssetRelation < ActiveRecord::Base
  belongs_to :asset, :class_name => "Asset"
  belongs_to :related_object, :polymorphic => true

  validates_presence_of :asset

  before_create :set_attribute_values

  # Return the name (used for foot-text of images, for example) for a given asset and field
  def self.name_for_asset(field, asset, related_object)
    asset = Asset.gfind(asset)
    ar = self.find(:first, :conditions => {:field_name => field.to_s, :asset_id => asset.id, :related_object_type => related_object.class.base_class.to_s, :related_object_id => related_object.id})
    return asset.name if ar.nil?
    ar.name
  end

  # Allows to define default values to be used when asset relations are created
  # automatically (by assigning assets to an instance)
  def self.default_values owner, reflection
    uhook_default_values owner, reflection
  end

  private

  # Ensures the position and name attributes are filled
  def set_attribute_values
    result = if related_object
      set_asset_name     unless self.name
      set_lower_position unless self.position
    else
      # related_object is validated here due to how nested_attributes work
      errors.add(:related_object, :blank)
      false
    end
    # if the uhook returns false, then stop the propagation
    result && (uhook_set_attribute_values != false)
  end

  # sets the name of the relation to the asset name
  def set_asset_name
    write_attribute :name, asset.name
  end

  # sets the max position to this element
  def set_lower_position
    write_attribute :position, related_object.send("#{field_name}_asset_relations").map(&:position).compact.max.to_i + 1
  end

end
