class AssetPublic < Asset
  file_attachment :resource, :visibility => "public", 
                  :styles => Ubiquo::Config.context(:ubiquo_media).get(:media_styles_list),
                  :processors => Ubiquo::Config.context(:ubiquo_media).get(:media_processors_list),
                  :storage => Ubiquo::Config.context(:ubiquo_media).get(:media_storage)
  
  validates_attachment_presence :resource
end
