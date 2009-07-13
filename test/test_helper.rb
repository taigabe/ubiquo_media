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
  # mock for params, filter_info, render_filter and other helper methods
  UbiquoMedia::Connectors::Base.current_connector::UbiquoAssetsController::Helper.expects(:params).at_least(0).returns({})
  UbiquoMedia::Connectors::Base.current_connector::UbiquoAssetsController::Helper.expects(:filter_info).at_least(0).returns('')
  UbiquoMedia::Connectors::Base.current_connector::UbiquoAssetsController::Helper.expects(:render_filter).at_least(0).returns('')
end
