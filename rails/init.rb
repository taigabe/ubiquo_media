require 'ubiquo_media'

config.after_initialize do
  UbiquoMedia::Connectors.load!
end

Ubiquo::Plugin.register(:ubiquo_media, directory, config) do |config|
  config.add :assets_elements_per_page
  config.add_inheritance :assets_elements_per_page, :elements_per_page
  config.add :media_selector_list_size, 3
  config.add :assets_access_control, lambda{
    access_control :DEFAULT => 'media_management'
  }
  config.add :assets_permit, lambda{
   permit?('media_management')
  }
  config.add :assets_string_filter_enabled, true
  config.add :assets_tags_filter_enabled, true
  config.add :assets_asset_types_filter_enabled, true
  config.add :assets_asset_visibility_filter_enabled, true
  config.add :assets_date_filter_enabled, true
  config.add :assets_default_order_field, 'assets.id'
  config.add :assets_default_sort_order, 'desc'
  config.add :asset_types_icons, { :doc => "icon_doc.png",
                                   :video => "icon_video.png",
                                   :audio => "icon_audio.png",
                                   :flash => "icon_flash.png",
                                   :other => "icon_other.png" }
  config.add :mime_types, { :image => ["image"],
                            :video => ["video"],
                            :doc => ["text"],
                            :audio => ["audio"],
                            :flash => ["swf", "x-shockwave-flash"] }
  config.add :media_styles_list, { :thumb => "100x100>" }
  
  config.add :force_visibility, "public" # set to public or protected to force it to the entire application

  config.add :connector, :standard
end

