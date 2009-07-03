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
    end
  end
end 
