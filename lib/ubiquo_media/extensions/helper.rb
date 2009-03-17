module UbiquoMedia
  module Extensions
    module Helper
      def media_tab(navtab)
        navtab.add_tab do |tab|
          tab.text = I18n.t("ubiquo.media.media")
          tab.title = I18n.t("ubiquo.media.media_title")
          tab.highlights_on({:controller => "ubiquo/assets"})
          tab.link = ubiquo_assets_path
        end if ubiquo_config_call(:assets_permit, {:context => :ubiquo_media})
      end
    end
  end
end
