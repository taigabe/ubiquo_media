require File.dirname(__FILE__) + "/../../../../test/test_helper.rb"

def save_current_connector    
  @old_connector = UbiquoMedia::Connectors::Base.current_connector
end

def reload_old_connector
  @old_connector.load!    
end
