require File.dirname(__FILE__) + "/../../../../test/test_helper.rb"

def save_current_connector    
  @old_connector = UbiquoMedia::Connectors::Base.current_connector
end

def reload_old_connector
  @old_connector.load!    
end

def mock_params
  Ubiquo::AssetsController.any_instance.expects(:params).at_least_once.returns({:asset => {}})
end
