require File.dirname(__FILE__) + "/../../../../test/test_helper.rb"


def save_current_connector    
  @old_connector = UbiquoMedia::Connectors::Base.current_connector
end

def reload_old_connector
  @old_connector.load!    
end

def mock_params params = nil
  Ubiquo::AssetsController.any_instance.expects(:params).at_least(0).returns(params || {:asset => {}})
end

def mock_session session = nil
  Ubiquo::AssetsController.any_instance.expects(:session).at_least(0).returns(session || {:asset => {}})
end

# Prepares the proper mocks for a hook that will be using controller features
def mock_controller
  mock_params
  mock_session
end

# Prepares the proper mocks for a hook that will be using helper features
def mock_helper
  # we stub well-known usable helper methods along with particular connector added methods
  stubs = {
    :params => {}, :t => '', :filter_info => '',
    :render_filter => '', :link_to => ''
  }.merge(UbiquoMedia::Connectors::Base.instance_variable_get('@methods_with_returns') || {})
  
  stubs.each_pair do |method, retvalue|
    UbiquoMedia::Connectors::Base.current_connector::UbiquoAssetsController::Helper.stubs(method).returns(retvalue)
  end  
end

# Used to add particular helper expectations from the connectors
def add_mock_helper_stubs(methods_with_returns)
  future_stubs = (UbiquoMedia::Connectors::Base.instance_variable_get('@methods_with_returns') || {}).merge(methods_with_returns)
  UbiquoMedia::Connectors::Base.instance_variable_set('@methods_with_returns', future_stubs)
end
