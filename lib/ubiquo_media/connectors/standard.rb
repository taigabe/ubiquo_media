module UbiquoMedia
  module Connectors
    class Standard < Base
      
      
      module Asset
        
        def self.included(klass)
          klass.send(:extend, ClassMethods)
        end
        
        module ClassMethods
          # Applies any required extra scope to the filtered_search method
          def uhook_filtered_search
            yield
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
      
#      
#      module UbiquoComponentsController
#        def self.included(klass)
#          klass.send(:include, InstanceMethods)
#        end
#        module InstanceMethods
#          
#          # returns the component for the lightwindow. 
#          # Will be rendered in their ubiquo/_form view
#          def uhook_find_component
#            @component = Component.find(params[:id])
#          end
#          
#          # modify the created component and return it. It's executed in drag-drop.
#          def uhook_prepare_component(component)
#            component
#         end
#          
#          # Destroys a component
#          def uhook_destroy_component(component)
#            component.destroy
#          end
#          
#          # updates a component. 
#          # Fields can be found in params[:component] and component_id in params[:id]
#          # must returns the updated component
#          def uhook_update_component
#            component = Component.find(params[:id])
#            params[:component].each do |field, value|
#              component.send("#{field}=", value)
#            end
#            component.save
#            component
#          end
#          
#        end
#      end
#
#      module UbiquoMenuItemsController
#        def self.included(klass)
#          klass.send(:include, InstanceMethods)
#        end
#        module InstanceMethods
#          
#          # gets Menu items instances for the list and return it
#          def uhook_find_menu_items
#            MenuItem.roots
#          end
#          
#          # initialize a new instance of menu item
#          def uhook_new_menu_item
#            MenuItem.new(:parent_id => (params[:parent_id] || 0), :is_active => true)
#          end
#          
#          # creates a new instance of menu item
#          def uhook_create_menu_item
#            mi = MenuItem.new(params[:menu_item])
#            mi.save
#            mi
#          end
#          
#          #updates a menu item instance. returns a boolean that means if update was done.
#          def uhook_update_menu_item(menu_item)
#            menu_item.update_attributes(params[:menu_item])
#          end
#          
#          #destroys a menu item instance. returns a boolean that means if destroy was done.
#          def uhook_destroy_menu_item(menu_item)
#            menu_item.destroy
#          end
#
#          # loads all automatic menu items
#          def uhook_load_automatic_menus
#            AutomaticMenu.find(:all, :order => 'name ASC')  
#          end
#        end
#      end
#
      module UbiquoAssetsController
        def self.included(klass)
          klass.send(:include, InstanceMethods)
          klass.send(:helper, Helper)
        end
        
        module Helper
          # Returns a string with extra filters for assets
          
          def uhook_asset_filters
            ''
          end

          # Returns an array with any display information for extra assets filters
          def uhook_asset_filters_info
            []
          end
        end
        
        module InstanceMethods
          
          # Returns a hash with extra filters to apply
          def uhook_index_filters
            {}
          end
          
          # Initializes a new instance of asset.
          def uhook_new_asset
            ::AssetPublic.new
          end
          
          # Creates a new instance of asset.
          def uhook_create_asset visibility
            visibility.new(params[:asset])
          end
         
#          #updates an asset instance. returns a boolean that means if update was done.
#          def uhook_update_asset(asset)
#            asset.update_attributes(params[:asset])
#          end
#
          #destroys an asset instance. returns a boolean that means if the destroy was done.
          def uhook_destroy_asset(asset)
            asset.destroy
          end
        end
      end
      
      module Migration
        
        def self.included(klass)
          klass.send(:extend, ClassMethods)
        end
        
        module ClassMethods
          def uhook_create_assets_table
            create_table :assets do |t|
              yield t
            end
          end
        end
      end
      
    end
  end
end
