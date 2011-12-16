module Ubiquo::AssetsHelper

  def asset_filters
    string_filter_enabled = Ubiquo::Config.context(:ubiquo_media).get(:assets_string_filter_enabled)
    type_filter_enabled = Ubiquo::Config.context(:ubiquo_media).get(:assets_asset_types_filter_enabled)
    visibility_filter_enabled = (Ubiquo::Config.context(:ubiquo_media).get(:assets_asset_visibility_filter_enabled) && !Ubiquo::Config.context(:ubiquo_media).get(:force_visibility))
    date_filter_enabled = Ubiquo::Config.context(:ubiquo_media).get(:assets_date_filter_enabled)

    asset_types =  @asset_types.map{|lk| OpenStruct.new(:key => lk.id, :name => I18n.t("ubiquo.asset_type.names.#{lk.key}"))}

    filters_for 'Asset' do |f|
      f.text(:caption => t('ubiquo.media.text')) if string_filter_enabled
      f.link(:type, asset_types, {
        :id_field => :key,
        :caption => t('ubiquo.media.type'),
        :all_caption => t('ubiquo.media.all')
      }) if type_filter_enabled
      f.link(:visibility, @asset_visibilities, {
        :caption => t('ubiquo.media.visibility'),
        :id_field => :key
      }) if visibility_filter_enabled
      f.date({
        :field => [:filter_created_start, :filter_created_end],
        :caption => t('ubiquo.media.creation')
      }) if date_filter_enabled
      # uhook_asset_filters f
    end
  end

  # Styles that can be cropped
  def media_styles_croppable_list
    list = Ubiquo::Config.context(:ubiquo_media).get(:media_styles_list)
    # The main styles are not croppable as they belong to the core
    Ubiquo::Config.context(:ubiquo_media).get(:media_core_styles).each do |s|
      list.delete(s)
    end
    # Filter the formats that are not strings like "300x200#"
    list.delete_if{|k,v| !v.respond_to?( :match )}
    list
  end

  # Returns the size scale comparing base_to_crop with original
  def resize_ratio_for asset
    base_geo = asset.geometry(:base_to_crop)
    original_geo = asset.geometry
    # Returning the biggest size as the ratio will be more exact.
    field = base_geo.width > base_geo.height ? :width : :height
    #Ratio to original / base
    original_geo.send(field).to_f / base_geo.send(field).to_f
  end
  
  # Returns the message to show when other elements use this asset. Nil otherways.
  def shared_asset_warning_message_for asset, params
    count = asset.asset_relations.count
    if count > 0 &&
        Ubiquo::Config.context(:ubiquo_media).get(:advanced_edit_warn_user_when_changing_asset_in_use)
      
      # Alert when we are editing an asset which is used elsewhere, in other models.
      do_warn = if count == 1 && params[:current_id].to_i > 0
        related_object = asset.asset_relations.first.related_object
        unless related_object.is_a?( params[:current_type].classify.constantize ) && 
            related_object.id == params[:current_id].to_i
          true # We are editing an asset that is related to another instance, not ours, so warn.
        end
      else
        # Notice: when we are advanced_editing an element which is related to a 
        # translatable model we'll warn even if it's :translation_shared
        # TODO: manage when it's a relation in a translation_shared relation
        threshold = (Ubiquo::Config.context(:ubiquo_media).get(:advanced_edit_warn_user_when_changing_asset_in_use_threshold) rescue 1)
        threshold <= count # More than the limit so warn!
      end 
      t("ubiquo.media.affects_all_related_elements", :count => asset.asset_relations.count) if do_warn
    end
  end

end
