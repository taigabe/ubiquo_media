require 'ubiquo'

module UbiquoMedia
  class Engine < Rails::Engine
    include Ubiquo::Engine::Base

    initializer :load_extensions do
      require 'ubiquo_media/connectors'
      require 'ubiquo_media/extensions'
      require 'ubiquo_media/media_selector'
      require 'ubiquo_media/version'
    end

    initializer :register_ubiquo_plugin do
      require 'ubiquo_media/init_settings.rb'
      UbiquoMedia::Connectors.load!
      Ubiquo::Helpers::UbiquoFormBuilder.initialize_method("media_selector",
      Ubiquo::Config.context(:ubiquo_media).get(:ubiquo_form_builder_media_selector_tag_options).dup)
    end

    initializer :load_connector, :after => :load_config_initializers do
      UbiquoMedia::Connectors.load!
      Ubiquo::Helpers::UbiquoFormBuilder.initialize_method("media_selector",
        Ubiquo::Config.context(:ubiquo_media).get(:ubiquo_form_builder_media_selector_tag_options).dup)
    end


  end
end
