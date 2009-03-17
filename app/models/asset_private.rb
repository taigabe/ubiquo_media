class AssetPrivate < Asset
  file_attachment :resource, :visibility => "protected"
  validates_attachment_presence :resource
end
