module UbiquoMedia
  module Connectors
    class I18n < Base
      
      
      module Asset
        
        def self.included(klass)
          klass.send(:extend, ClassMethods)
          klass.send(:translatable, :name)
          I18n.register_uhooks klass, ClassMethods
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
          def uhook_edit_asset_sidebar
            show_translations(@asset)
          end
        end
        
        module InstanceMethods
          
          # Returns a hash with extra filters to apply
          def uhook_index_filters
            {:locale => params[:filter_locale]}
          end
          
          # Initializes a new instance of asset.
          def uhook_new_asset
            ::AssetPublic.translate(params[:from], current_locale, :copy_all => true)
          end
          
          # Creates a new instance of asset.
          def uhook_create_asset visibility
            asset = visibility.new(params[:asset])
            asset.locale = current_locale
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
        end
      end
      
    end
  end
end
