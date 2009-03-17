module UbiquoMedia
  module Extensions
    autoload :Helper, 'ubiquo_authentication/extensions/helper'
  end
end

ActionController::Base.helper(UbiquoMedia::Extensions::Helper)


