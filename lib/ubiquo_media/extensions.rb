module UbiquoMedia
  module Extensions
    autoload :Helper, 'ubiquo_media/extensions/helper'
  end
end

ActionController::Base.helper(UbiquoMedia::Extensions::Helper)


