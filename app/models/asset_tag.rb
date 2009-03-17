class AssetTag < ActiveRecord::Base
  belongs_to :asset, :class_name => "Asset"
  belongs_to :tag
end
