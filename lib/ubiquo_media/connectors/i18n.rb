module UbiquoMedia
  module Connectors
    class I18n < Standard

      # Validates the ubiquo_i18n-related dependencies
      def self.validate_requirements
        unless Ubiquo::Plugin.registered[:ubiquo_i18n]
          raise ConnectorRequirementError, "You need the ubiquo_i18n plugin to load #{self}"
        end
        [::AssetRelation].each do |klass|
          if klass.table_exists?
            klass.reset_column_information
            columns = klass.columns.map(&:name).map(&:to_sym)
            unless [:locale, :content_id].all?{|field| columns.include? field}
              if Rails.env.test?
                ::ActiveRecord::Base.connection.change_table(klass.table_name, :translatable => true){}
                klass.reset_column_information
              else
                raise ConnectorRequirementError,
                  "The #{klass.table_name} table does not have the i18n fields. " +
                  "To use this connector, update the table enabling :translatable => true"
              end
            end
          end
        end
      end

      def self.unload!
        ::AssetRelation.untranslatable
        ::AssetRelation.reflections.map(&:first).each do |reflection|
          ::AssetRelation.unshare_translations_for reflection
        end
      end

      module AssetRelation

        def self.included(klass)
          klass.send(:extend, ClassMethods)
          klass.send(:translatable, :name, :position)
          klass.send(:share_translations_for, :asset, :related_object)
          I18n.register_uhooks klass, ClassMethods
        end

        module ClassMethods

          # Applies any required extra scope to the filtered_search method
          def uhook_filtered_search filters = {}
            filter_locale = filters[:locale] ?
              {:find => {:conditions => ["asset_relations.locale <= ?", filters[:locale]]}} : {}

            with_scope(filter_locale) do
              yield
            end
          end

          # Returns default values for automatically created Asset Relations
          def uhook_default_values owner, reflection
            if owner.class.is_translatable?
              {:locale => owner.locale}
            else
              {}
            end
          end
        end
      end

      module Migration

        def self.included(klass)
          klass.send(:extend, ClassMethods)
          I18n.register_uhooks klass, ClassMethods
        end

        module ClassMethods
          include Standard::Migration::ClassMethods

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
            klass.send(:include, InstanceMethods)
            I18n.register_uhooks klass, ClassMethods, InstanceMethods
            update_reflections_for_uhook_media_attachment
          end

          # Updates the needed reflections to activate the :translation_shared flag
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
              if parameters[:options][:translation_shared]
                field = parameters[:field]
                parameters[:klass].share_translations_for field, :"#{field}_asset_relations"
              end
            end
          end

          module InstanceMethods
            include Standard::ActiveRecord::Base::InstanceMethods
          end
        end
      end

    end
  end
end
