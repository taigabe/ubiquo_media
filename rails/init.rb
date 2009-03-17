require 'ubiquo_media'

default_per_page = Ubiquo::Config.get(:elements_per_page)
Ubiquo::Plugin.register(:ubiquo_media, directory, config) do |config|
  config.add :assets_elements_per_page, default_per_page
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

end
