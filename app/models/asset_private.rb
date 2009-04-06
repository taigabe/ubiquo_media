class AssetPrivate < Asset
  file_attachment :resource, :visibility => "protected", :styles => { :thumb => "100x100>" }
  validates_attachment_presence :resource
end
