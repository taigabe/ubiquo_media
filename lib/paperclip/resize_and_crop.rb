module Paperclip
  # Resizes an image to the :resize defined format, and then crops from the center
  # to achieve a geometry of :crop
  # Note that the :crop processor option does not need the trailing '#'
  class ResizeAndCrop < Thumbnail

    class InstanceNotGiven < ArgumentError; end

    attr_accessor :as_parent

    def initialize(file, options = {},attachment = nil)
      super
      @attachment = attachment
      self.as_parent = true
      if( options[:crop_to] || self.asset_area )
        self.as_parent = false
        @crop_to = options[:crop_to] || (asset_area && asset_area.crop_to )
        #@resize_to = options[:resize_to] || (asset_area.resize_to
      end
    end

    # Overwritting the thumb methods
    def transformation_command
      return super if as_parent

      # We get the super and add methods to them
      trans = ""
      trans << " -crop \"#{@crop_to}\" +repage " if @crop_to
      trans
    end

    def make
      return super if as_parent
      # First we crop
      file = super
      # After allow to apply the format.
      Thumbnail.new( file, options, @attachment).make
    end

    protected
    def asset_area
      @asset_area ||= @attachment.instance.asset_areas.find_by_style(style.to_s)
    end

    # Retrieves the style to which this processor is being attached
    def style
      # FIXME: this is an ugly solution but Paperclip does not give us the style
      # which is being used when creates a Processor.
      #
      # To bypass our need to know the style, we deduce it from the style properties
      # recieved in the options param.
      #
      # Ugly because the logical way would be to get the style in the initialize
      @attachment.styles.each do |key, st|
        return key if st.geometry == options[:geometry] && options[:processors] == st.processors
      end
      raise t("ubiquo.media.paperclip.resize_and_crop.error_no_style_matched") % options.inspect
    end
  end
end
