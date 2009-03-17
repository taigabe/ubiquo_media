class AssetPublic < Asset
  file_attachment :resource, :visibility => "public"
  validates_attachment_presence :resource
end
