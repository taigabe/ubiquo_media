class AssetPublic < Asset
  file_attachment :resource, :visibility => "public", :styles => { :thumb => "100x100>" }
  validates_attachment_presence :resource
end
