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
#Versions are specified on the Asset model. Change the file_column_attribute call to add more versions:
#
#  file_column_attribute :resource, :magick => {
#    :image_required => false,
#    :versions => {
#      :thumb => {:size => "50x50"},
#      :normal => {:size => "500x500>"},
#    }
#  }

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
            define_method('<<') do |assets|
              assets = case assets
                       when Array
                         assets
                       else
                         [assets]
                       end
              assets.each do |asset|
                next if self.is_full?
                name = nil
                asset = case asset
                        when String, Fixnum
                          Asset.gfind(asset.to_i)
                        when Hash
                          name = asset["name"]
                          Asset.gfind(asset["id"].to_i)
                        when Asset
                          Asset.gfind(asset)
                        else
                          raise "Not acceptable type"
                        end
                next if asset.nil?
                next unless self.accepts?(asset)
                AssetRelation.scoped_creation(field, (name || asset.name)) do
                  self.concat(asset)
                end
              end
            end
            define_method('is_full?') do
              return false if self.options[:size].to_sym == :many
              self.size >= self.options[:size]
            end
            define_method('accepts?') do |asset|
              refresh_types if options[:asset_types].nil?
              options[:asset_types].include?(asset.asset_type)
            end
            define_method('options') do
              refresh_types if options[:asset_types].nil?
              options
            end
            define_method('refresh_types') do
              options[:types] = [options[:types]].flatten.map(&:to_sym)
              if(options[:types].include?(:ALL))
                options[:asset_types] = AssetType.find(:all)
              else
                options[:asset_types] = options[:types].map{|o|AssetType.gfind(o)}
              end
            end
          end


          self.has_many(field, {
                          :through => :asset_relations,
                          :class_name => "::Asset",
                          :source => :asset,
                          :conditions => ["asset_relations.field_name = ?", field.to_s],
                          :order => "asset_relations.position ASC"
                        },&proc)

          define_method("name_for_asset") do |field, asset|
            return "" if field.to_s.blank? || asset.nil?
            AssetRelation.name_for_asset(field, asset, self)
          end
          
          define_method("#{field}_ids=") do |values|
            instance_variable_set("@#{field}_values_ids", values.reject(&:blank?))
          end

          define_method("#{field}_ids") do
            ids=instance_variable_get("@#{field}_values_ids")
            ids || send(field).map(&:id)
          end

          after_save "#{field}_after_save"

          define_method("#{field}_after_save") do
            unless instance_variable_get("@#{field}_values_ids").nil?
              send(field).delete(send(field))
              send(field) << instance_variable_get("@#{field}_values_ids")
              instance_variable_set "@#{field}_values_ids", nil
            end
            true
          end
        end
      end

    end
  end
end
