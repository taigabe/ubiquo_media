#= Media
#
#Ubiquo template provides a simple media management for your application.
#
#By default, the most common asset types are already created (video, flash, document, audio, image, other). Edit the fixtures file <tt>db/dev_bootstrap/asset_types.yml</tt> to add more.
#
#Asset files will be store at <tt>public/media/assets/id</tt>.
#
#== Add media to your models
#
#The media library allows to insert a media field into a model. On this example we include a _media_attachment_ attribute called _images_, with a maximum of 2 elements and accepting only images.
#
#  class ExampleModel
#	  media_attachment :images, :size => 2, :types => ["image"]
#    ...
#  end
#
#Note: For convention, the attribute name should be always plural no matter if it contains a single element (_size_ option is 1). The _media_attachment_ accessor always returns an array.
#
#_media_attachment_ creates some methods on the object which can be useful on validations:
#
#  validates_length_of :images_ids, :minumum => 1, :message => t('should contain at least one image')
#
#== Add media selectors to your views
#
#In your views you only need to use the _media_selector_ helper:
#
#  <% form_for ... do |form| %>
#	  ....
#	  <%= media_selector form, :images %>
#	  ....
#  <% end %>
#
#== Add media to your views
#
#Get an url to your media with _url_for_media_attachment_:
#
#  <%= link_to("a link to first image image", url_for_media_attachment(object.images.first)) %>
#
#== Using thumbnails
#
#Generate url for your media columns with _url_for_media_attachment_ and the magick _version_ parameter:
#
#  <%= link_to("a link to first thumbnail image", url_for_media_attachment(object.thumbnail.first, :thumb)) %>
#
# You can also specify paperclip styles to store different versions of the asset
#

module UbiquoMedia
  module MediaSelector
    module ActiveRecord

      def self.append_features(base)
        super
        base.extend(ClassMethods)
      end

      module ClassMethods


        DEFAULT_OPTIONS = {
          :size => 1,
          :types => :ALL
        }

        # Class method for ActiveRecord. This creates relationship to Assets only calling this method. You must pass the desired field value and custom options.
        # custom options:
        #   :size   => the max size of assets assigned. Can be an integer or :many if no limit. Default: 1
        #   :types  => array with allowed asset types keys. Can be a single key or an Array. if includes :ALL will accept all types. Default: ALL
        #   :styles => paperclip styles
        #
        # EXAMPLES:
        #
        #   media_attachment :simple
        #   media_attachment :multiple, :size => :many
        #   media_attachment :sized, :size => 2
        #   media_attachment :all_types, :types => :ALL
        #   media_attachment :some_types, :types => %w{audio video}

        def media_attachment(field, options = {})
          options.reverse_merge!(DEFAULT_OPTIONS)

          self.has_many(:asset_relations, {
              :as => :related_object,
              :class_name => "::AssetRelation",
              :dependent => :destroy,
              :order => "asset_relations.position ASC"
          }) unless self.respond_to?(:asset_relations)

          proc = Proc.new do
            def is_full?
              return false if self.options[:size].to_sym == :many
              self.size >= self.options[:size]
            end

            def accepts? asset
              proxy_owner.send("accepts_asset_for_#{self.field}?", asset)
            end

            define_method('field') do
              field
            end

            define_method('options') do
              options
            end

            define_method('reset_positions') do |assets|
              assets.each_with_index do |asset, i|
                relation = proxy_owner.send("#{field}_asset_relations").select do |ar|
                  ar.asset == asset
                end.first
                relation.update_attribute :position, i+1 if relation
              end
            end

            # Automatically set the required attr_name when creating through the through
            define_method 'construct_owner_attributes' do |reflection|
              super(reflection).merge(:field_name => field.to_s).merge(AssetRelation.default_values(proxy_owner, reflection))
            end
          end

          define_method("name_for_asset") do |asset_field, asset|
            return "" if asset_field.to_s.blank? || asset.nil?
            AssetRelation.name_for_asset(asset_field, asset, self)
          end


          self.has_many(:"#{field}_asset_relations",
            :class_name => "::AssetRelation",
            :as => :related_object,
            :conditions => {:field_name => field.to_s},
            :order => "asset_relations.position ASC",
            :dependent => :destroy
          )

          self.has_many(field, {
            :through => :"#{field}_asset_relations",
            :class_name => "::Asset",
            :source => :asset,
            :order => "asset_relations.position ASC"
          },&proc)

          accepts_nested_attributes_for :"#{field}_asset_relations", :reject_if => :all_blank, :allow_destroy => true

          validate "required_amount_of_assets_in_#{field}"

          validate "valid_asset_types_in_#{field}"

          # To get the current assets related (in memory).
          # CAUTION: it can return Assets or AssetRelations
          define_method "#{field}_current_asset_relations" do
            # Note that the field to watch depends on how relations have been assigned.
            # Usually, in the controller flow, will be _field_asset_relations_, but if it's
            # empty, we'll take a look to _field_ and if there is something, we assume
            # that this field is being used, for example in a migration or in console.
            # This is a far from perfect approach and could be a bug in some situations,
            # but it's the best way we've found to correctly perform this validation
            # in the usual use cases without monkeypatching.
            objects = send("#{field}_asset_relations").present? ?
              send("#{field}_asset_relations").reject(&:marked_for_destruction?) :
              send(field)
            uhook_current_asset_relations(objects)
          end

          define_method "required_amount_of_assets_in_#{field}" do
            required_amount = case options[:required]
            when TrueClass
              options[:size] == :many ? 1 : options[:size]
            when Fixnum
              options[:required]
            end

            current_amount = send("#{field}_current_asset_relations").size

            if required_amount
              if current_amount < required_amount
                errors.add(field, :not_enough_assets)
              # :many is a open ended size, we don't have a superior limit
              elsif options[:size] != :many && current_amount > options[:size]
                errors.add(field, :too_much_assets)
              end
            end
          end

          define_method "valid_asset_types_in_#{field}" do
            invalid = send("#{field}_current_asset_relations").to_a.detect do |asset|
              # current_asset_relations can return assets or asset_relations
              asset = asset.respond_to?( :asset ) ? asset.asset : asset
              if asset
                !self.send("accepts_asset_for_#{field}?", asset)
              else
                # FIXME: some I18nTest methods fail 'cause the asset does not exist
                # Some weird cases the asset does not exist, so we cannot validate.
                self.logger.warn("Asset type could not be checked for #{self.inspect}")
                false
              end
            end.present?
            errors.add(field, :wrong_asset_type) if invalid
          end

          define_method "accepts_asset_for_#{field}?" do |asset|
            types = Array(options[:types]).clone
            if types.include?(:ALL)
              true
            else
              asset.asset_type && types.include?(asset.asset_type.key)
            end
          end

          # Like Rails' nested_attributes (uses it), but it's a hard-assign,
          # any non-present relation will be destroyed.
          define_method "#{field}_attributes=" do |attrs|
            attrs_as_array = if attrs.is_a?(Hash)
              # this is to fit assign_nested_attributes_for_collection_association
              attrs.sort_by { |index, _| index.to_i }.map { |_, attributes| attributes }
            else
              # already an array, or it will break anyway
              attrs
            end

            current_ids = send("#{field}_asset_relations").map(&:id).map(&:to_s)
            new_ids = attrs_as_array.map{|attr| attr[:id] || attr['id']}.compact.map(&:to_s)
            missing_ids = current_ids - new_ids
            destroyable = missing_ids.map{ |id| {'id' => id, '_destroy' => true} }
            attrs_to_set = attrs_as_array + destroyable

            uhook_media_attachment_set_attributes!(field, attrs_to_set)

            send("#{field}_asset_relations_attributes=", attrs_to_set)
          end

          # Rails tries to be lazy when replacing a collection, but we want to
          # redefine the position of each asset, so we need to postprocess +assets+
          define_method "#{field}_with_position=" do |assets|
            send("#{field}_without_position=", assets)
            send(field).reset_positions(assets)
          end

          alias_method_chain "#{field}=", :position

          uhook_media_attachment field, options
        end
      end

    end
  end
end
