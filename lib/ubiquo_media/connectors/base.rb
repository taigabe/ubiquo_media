module UbiquoMedia
  module Connectors
    class Base
      
      # loads this connector. It's called if that connector is used
      def self.load!
        ::Asset.send(:include, self::Asset)
#        ::AssetRelation.send(:include, self::AssetRelation)
        ::Ubiquo::AssetsController.send(:include, self::UbiquoAssetsController)
        ::ActiveRecord::Migration.send(:include, self::Migration)
        UbiquoMedia::Connectors::Base.set_current_connector self
      end
      
      def self.current_connector
        @current_connector
      end
      
      def self.set_current_connector klass
        @current_connector = klass
      end
      
      # Register the uhooks methods in connectors to be used in klass
      def self.register_uhooks klass, *connectors
        connectors.each do |connector|
          connector.instance_methods.each do |method|
            if method =~ /^uhook_(.*)$/
              connectorized_method = "uhook_#{self.to_s.demodulize.underscore}_#{$~[1]}"
              connector.send :alias_method, connectorized_method, method
              if klass.instance_methods.include?(method)
                klass.send :alias_method, method, connectorized_method
              else
                class << klass
                  self
                end.send :alias_method, method, connectorized_method              
              end
            end
          end
        end
      end
    end
    
  end
end 
