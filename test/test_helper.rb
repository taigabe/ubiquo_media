require File.dirname(__FILE__) + "/../../../../test/test_helper.rb"
require 'mocha'

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

def mock_routes
  Ubiquo::AssetsController.any_instance.expects(:ubiquo_assets_path).at_least(0).returns('')  
end

def mock_response
  Ubiquo::AssetsController.any_instance.expects(:redirect_to).at_least(0)
end

# Prepares the proper mocks for a hook that will be using controller features
def mock_controller
  mock_params
  mock_session
  mock_routes
  mock_response
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


# Improvement for Mocha's Mock: stub_everything with a default return value other than nil.
class Mocha::Mock
  
  def stub_default_value= value
    @everything_stubbed_default_value = value
  end
  
  if !self.instance_methods.include?(:method_missing_with_stub_default_value.to_s)
    
    def method_missing_with_stub_default_value(symbol, *arguments, &block)
      value = method_missing_without_stub_default_value(symbol, *arguments, &block)
      if !@expectations.match_allowing_invocation(symbol, *arguments) && !@expectations.match(symbol, *arguments) && @everything_stubbed
        @everything_stubbed_default_value
      else
        value
      end
    end

    alias_method_chain :method_missing, :stub_default_value

  end
  
end

