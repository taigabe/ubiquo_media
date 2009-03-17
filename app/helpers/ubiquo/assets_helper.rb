module Ubiquo::AssetsHelper
  def asset_filters_info(params)
    string_filter = if Ubiquo::Config.context(:ubiquo_media).get(:assets_string_filter_enabled)
      filter_info(:string, params,
        :field => :filter_text,
        :caption => t('ubiquo.media.text'))
    else
      nil
    end
    tags_filter = if Ubiquo::Config.context(:ubiquo_media).get(:assets_tags_filter_enabled)
      filter_info(:links, params,
        :field => :filter_tag,
        :caption => t('ubiquo.media.tag'))     
    else
      nil
    end
    asset_types_filter = if Ubiquo::Config.context(:ubiquo_media).get(:assets_asset_types_filter_enabled)
      filter_info(:links, params,
        :caption => t('ubiquo.media.type'),
        :all_caption => t('ubiquo.media.all'),
        :field => :filter_type,
        :collection => @asset_types,
        :model => :asset_types,
        :id_field => :id,
        :name_field => :name)   
    else
      nil
    end
    asset_visibility_filter = if Ubiquo::Config.context(:ubiquo_media).get(:assets_asset_visibility_filter_enabled)
      filter_info(:links, params,
        :caption => t('ubiquo.media.visibility'),
        :field => :filter_visibility,
        :collection => @asset_visibilities,
        :id_field => :key,
        :name_field => :name)
    else
      nil
    end
    date_filter = if Ubiquo::Config.context(:ubiquo_media).get(:assets_date_filter_enabled)
      filter_info(:date, params,
        :caption => t('ubiquo.media.creation'),
        :field => [:filter_created_start, :filter_created_end])
    else
      nil
    end
    build_filter_info(string_filter, tags_filter, asset_types_filter, asset_visibility_filter, date_filter)
  end

  def asset_filters(url_for_options = {})
    string_filter = if Ubiquo::Config.context(:ubiquo_media).get(:assets_string_filter_enabled)
      render_filter(:string, url_for_options,
        :field => :filter_text,
        :caption => t('ubiquo.media.text'))
    else
      ''
    end
    tags_filter = if Ubiquo::Config.context(:ubiquo_media).get(:assets_tags_filter_enabled)
      render(:partial => 'tag_filter')   
    else
      ''
    end
    asset_types_filter = if Ubiquo::Config.context(:ubiquo_media).get(:assets_asset_types_filter_enabled)
      render_filter(:links, url_for_options,
        :caption => t('ubiquo.media.type'),
        :all_caption => t('ubiquo.media.all'),
        :field => :filter_type,
        :collection => @asset_types,
        :id_field => :id,
        :name_field => :name)
    else 
      ''
    end
    asset_visibility_filter = if Ubiquo::Config.context(:ubiquo_media).get(:assets_asset_visibility_filter_enabled)
      render_filter(:links, url_for_options,
        :caption => t('ubiquo.media.visibility'),
        :field => :filter_visibility,
        :collection => @asset_visibilities,
        :id_field => :key,
        :name_field => :name)
    else
      ''
    end                            
    date_filter = if Ubiquo::Config.context(:ubiquo_media).get(:assets_date_filter_enabled)
      render_filter(:date, url_for_options,
        :caption => t('ubiquo.media.creation'),
        :field => [:filter_created_start, :filter_created_end])      
    else
      ''
    end
    (string_filter + tags_filter + asset_types_filter + asset_visibility_filter + date_filter)
  end
  
end
