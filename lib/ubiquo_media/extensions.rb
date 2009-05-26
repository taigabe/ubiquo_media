module UbiquoMedia
  module Extensions
    autoload :Helper, 'ubiquo_media/extensions/helper'
  end
end

Ubiquo::Extensions::UbiquoAreaController.append_helper(UbiquoMedia::Extensions::Helper)


