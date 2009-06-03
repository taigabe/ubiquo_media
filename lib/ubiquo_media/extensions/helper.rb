module UbiquoMedia
  module Extensions
    module Helper
      
      # Adds a tab for the media section
      def media_tab(navtab)
        navtab.add_tab do |tab|
          tab.text = I18n.t("ubiquo.media.media")
          tab.title = I18n.t("ubiquo.media.media_title")
          tab.highlights_on({:controller => "ubiquo/assets"})
          tab.link = ubiquo_assets_path
        end if ubiquo_config_call(:assets_permit, {:context => :ubiquo_media})
      end
      
      # Return the thumbnail url for a given asset
      def thumbnail_url(asset)
        if asset.asset_type.key == "image"
          asset.resource.url(:thumb)
        else
          types_icons = Ubiquo::Config.context(:ubiquo_media).get(:asset_types_icons)
          "/images/ubiquo/#{types_icons[asset.asset_type.key.to_sym]}"
        end
      end      
    end
  end
end
