module UbiquoMedia
  module Connectors
    class I18n < Base
      
      
      module Asset
        
        def self.included(klass)
          klass.send(:extend, ClassMethods)
          klass.send(:translatable, :name, :description)
          klass.send(:include, InstanceMethods)
          I18n.register_uhooks klass, ClassMethods, InstanceMethods
        end
        
        module ClassMethods
          
          # Applies any required extra scope to the filtered_search method
          def uhook_filtered_search filters = {}
            filter_locale = filters[:locale] ?
              {:find => {:conditions => ["assets.locale <= ?", filters[:locale]]}} : {}
              
            with_scope(filter_locale) do
              yield
            end
          end
        end
        
        module InstanceMethods
          # Performs any necessary step after an update
          # This can be useful to handle the asset special attribute :resource
          def uhook_after_update
            # Updates :resource in translations, if this field has been updated
            if self.class.instance_variable_get('@original_resource_owner').blank?
              begin
                self.class.instance_variable_set('@original_resource_owner', self)
                # The resource we are copying must be saved for paperclip to work correctly
                self.resource.save
                translations.each do |translation|
                  translation.without_updating_translations do
                    translation.resource = self.resource
                    translation.save
                  end
                end
              ensure
                self.class.instance_variable_set('@original_resource_owner', nil)
              end
            end
          end
        end
        
      end
      
#      module AssetRelation
#        
#        def self.included(klass)
##          klass.send(:extend, ClassMethods)
##          klass.send(:include, InstanceMethods)
#        end
#        
##        module ClassMethods
##          # Applies any required extra scope to the filtered_search method
##          def uhook_filtered_search
##            yield
##          end
##        end
##        
#      end
      
      module UbiquoAssetsController
        def self.included(klass)
          klass.send(:include, InstanceMethods)
          klass.send(:helper, Helper)
          I18n.register_uhooks klass, InstanceMethods
        end
        
        module Helper
          # Returns a string with extra filters for assets
          def uhook_asset_filters url_for_options
            render_filter(:links, url_for_options,
              :caption => ::Asset.human_attribute_name("locale"),
              :field => :filter_locale,
              :collection => Locale.active,
              :id_field => :iso_code,
              :name_field => :native_name
            )
          end

          # Returns an array with any display information for extra assets filters
          def uhook_asset_filters_info
            [filter_info(
              :string, params,
              :field => :filter_locale,
              :caption => ::Asset.human_attribute_name("locale"))
            ]
          end
          
          # Returns content to show in the sidebar when editing an asset
          def uhook_edit_asset_sidebar asset
            show_translations(asset, :hide_preview_link => true)
          end
          
          # Returns content to show in the sidebar when creating an asset
          def uhook_new_asset_sidebar asset
            show_translations(asset, :hide_preview_link => true)
          end
          
          # Returns the available actions links for a given asset
          def uhook_asset_index_actions asset
            actions = []
            if asset.locale?(current_locale)
              actions << link_to(t("ubiquo.edit"), edit_ubiquo_asset_path(asset))
            end
            
            unless asset.locale?(current_locale)
              actions << link_to(
                t("ubiquo.translate"), 
                new_ubiquo_asset_path(:from => asset.content_id)
              )
            end
            
            actions << link_to(t("ubiquo.remove"), 
              ubiquo_asset_path(asset, :destroy_content => true), 
              :confirm => t("ubiquo.media.confirm_asset_removal"), :method => :delete
            )
            
            if asset.locale?(current_locale, :skip_any => true)
              actions << link_to(t("ubiquo.remove_translation"), ubiquo_asset_path(asset), 
                :confirm => t("ubiquo.media.confirm_asset_removal"), :method => :delete
              )
            end
            
            actions
          end
          
          # Returns any necessary extra code to be inserted in the asset form
          def uhook_asset_form form
            (form.hidden_field :content_id) + (hidden_field_tag(:from, params[:from]))
          end          
        end
        
        module InstanceMethods
          
          # Returns a hash with extra filters to apply
          def uhook_index_filters
            {:locale => params[:filter_locale]}
          end
          
          # Returns a subject that will have applied the index filters 
          # (e.g. a class, with maybe some scopes applied)
          def uhook_index_search_subject
            ::Asset.locale(current_locale, :ALL)
          end
          
          # Initializes a new instance of asset.
          def uhook_new_asset
            ::AssetPublic.translate(params[:from], current_locale, :copy_all => true)
          end
          
          # Performs any required action on asset when in edit
          def uhook_edit_asset asset
            unless asset.locale?(current_locale)
              redirect_to(ubiquo_assets_path)
              false
            end            
          end
          
          # Creates a new instance of asset.
          def uhook_create_asset visibility
            asset = visibility.new(params[:asset])
            asset.locale = current_locale
            if params[:from] && asset.resource_file_name.blank?
              asset.resource = visibility.find(params[:from]).resource
            end
            asset
          end
         
#          #updates an asset instance. returns a boolean that means if update was done.
#          def uhook_update_asset(asset)
#            asset.update_attributes(params[:asset])
#          end
#
          #destroys an asset instance. returns a boolean that means if the destroy was done.
          def uhook_destroy_asset(asset)
            destroyed = false
            if params[:destroy_content]
              destroyed = asset.destroy_content
            else
              destroyed = asset.destroy
            end
            destroyed
          end
        end
      end
      
      module Migration
        
        def self.included(klass)
          klass.send(:extend, ClassMethods)
          I18n.register_uhooks klass, ClassMethods
        end
        
        module ClassMethods
          def uhook_create_assets_table
            create_table :assets, :translatable => true do |t|
              yield t
            end
          end

          def uhook_create_asset_relations_table
            create_table :asset_relations, :translatable => true do |t|
              yield t
            end
          end
        end
      end
      
      module ActiveRecord
        module Base
        
          def self.included(klass)
            klass.send(:extend, ClassMethods)
            I18n.register_uhooks klass, ClassMethods
            update_reflections_for_uhook_media_attachment
          end
          
          # Updates the needed reflections for 
          def self.update_reflections_for_uhook_media_attachment
            ClassMethods.module_eval do
              module_function :uhook_media_attachment_process_call
            end
            I18n.get_uhook_calls(:uhook_media_attachment).flatten.each do |call|
              ClassMethods.uhook_media_attachment_process_call call
            end
          end

          module ClassMethods
            # called after a media_attachment has been defined and built
            def uhook_media_attachment field, options
              parameters = {:klass => self, :field => field, :options => options}
              I18n.register_uhook_call(parameters) {|call| call.first[:klass] == self && call.first[:field] == field}
              uhook_media_attachment_process_call parameters
            end
            
            protected
            
            def uhook_media_attachment_process_call parameters
              unless parameters[:options][:translation_shared].nil?
                # Mark the association as translation_shared
                parameters[:klass].reflections[parameters[:field]].options[:translation_shared] = 
                  parameters[:options][:translation_shared]
              end
            end
          end

        end
      end      
      
    end
  end
end
