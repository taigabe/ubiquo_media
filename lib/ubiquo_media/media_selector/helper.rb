module UbiquoMedia
  module MediaSelector
    module Helper
      def media_selector(form, field, options = {})
        @counter ||= 0
        @counter += 1
        locals = {
          :assets => form.object.send(field),
          :field => field,
          :object => form.object,
          :object_name =>  options[:object_name] || form.object_name.to_s,
          :visibility => options[:visibility],
          :counter => @counter
        }
        render :partial => 'ubiquo/asset_relations/media_selector.html.erb', :locals => locals
      end
      
      def view_asset_link(asset)
        link_to(t('ubiquo.media.asset_view'), url_for_media_attachment(asset), :class => 'view', :popup => true)
      end

      def url_for_media_attachment(asset, style = nil)
        url_for_file_attachment(asset, :resource, style)
      end
      # Return a selector containing all allowed types for a media_attachment field
      #
      # Example:
      # 
      # types = ["image", "doc"].map { |key| AssetType.find_by_key(key) }
      # type_selector("images", types)
      # 
      # Returns:   
      #
      # "<select id="asset_type_id_images" name="asset_type_id_images">
      #   <option value="1,2">-- All --</option>
      #   <option value="1">Image</option>
      #    <option value="2">Document</option>
      #  </select>"      
      def type_selector(counter, types)
        all_opt = [t('ubiquo.media.all'), types.collect(&:id).join(",")]  
        type_opts = [all_opt] + types.collect { |t| [t.name, t.id] } 
        select_tag "asset_type_id_#{counter}".to_sym, options_for_select(type_opts)
      end      
      
    end
  end
end
