require File.dirname(__FILE__) + "/../../test_helper"

class UbiquoMedia::Connectors::BaseTest < ActiveSupport::TestCase

  Base = UbiquoMedia::Connectors::Base
  
  test 'should_load_correct_modules' do
    ::Asset.expects(:include).with(Base::Asset)
    ::Ubiquo::AssetsController.expects(:include).with(Base::UbiquoAssetsController)
#    ::AssetRelation.expects(:include).with(Base::AssetRelation)
    ::ActiveRecord::Migration.expects(:include).with(Base::Migration)
    Base.expects(:set_current_connector).with(Base)
    Base.load!
  end
  
  test 'should_set_current_connector_on_load' do
    save_current_connector
    Base.load!
    assert_equal Base, Base.current_connector
    reload_old_connector
  end
  
  
  test 'uhook_create_assets_table_should_create_table' do
    ActiveRecord::Migration.expects(:create_table).with(:assets, anything)
    ActiveRecord::Migration.uhook_create_assets_table {}
  end
  
  test 'uhook_filtered_search_in_asset_should_yield' do
    Asset.expects(:all)
    Asset.uhook_filtered_search { Asset.all }
  end
  
  test 'uhook_index_filters_should_return_hash' do
    mock_controller
    assert Ubiquo::AssetsController.new.uhook_index_filters.is_a?(Hash)
  end
  
  test 'uhook_index_search_subject should return searchable' do
    mock_controller
    assert_nothing_raised do 
      Ubiquo::AssetsController.new.uhook_index_search_subject.filtered_search
    end
  end
  
  test 'uhook_new_asset_should_return_new_asset' do
    mock_controller
    asset = Ubiquo::AssetsController.new.uhook_new_asset 
    assert asset.is_a?(Asset)
    assert asset.new_record?
  end
  
  test 'uhook_create_asset_should_return_new_asset' do
    mock_controller
    %w{AssetPublic AssetPrivate}.each do |visibility|
      asset = Ubiquo::AssetsController.new.uhook_create_asset visibility.constantize
      assert_equal visibility, asset.class.to_s
      assert asset.new_record?
    end
  end

  test 'uhook_destroy_asset_should_destroy_asset' do
    mock_controller
    Asset.any_instance.expects(:destroy).returns(:value)
    assert_equal :value, Ubiquo::AssetsController.new.uhook_destroy_asset(Asset.new)
  end
  
  test 'uhook_asset_filters_should_return_string' do
    mock_helper
    Base.current_connector::UbiquoAssetsController::Helper.module_eval do
      module_function :uhook_asset_filters
    end
    assert Base.current_connector::UbiquoAssetsController::Helper.uhook_asset_filters('').is_a?(String)
  end

  test 'uhook_asset_filters_info_should_return_array' do
    mock_helper
    Base.current_connector::UbiquoAssetsController::Helper.module_eval do
      module_function :uhook_asset_filters_info
    end
    assert Base.current_connector::UbiquoAssetsController::Helper.uhook_asset_filters_info.is_a?(Array)
  end
  
  test 'uhook_edit_asset_sidebar_should_return_string' do
    mock_helper
    Base.current_connector::UbiquoAssetsController::Helper.module_eval do
      module_function :uhook_edit_asset_sidebar
    end
    assert Base.current_connector::UbiquoAssetsController::Helper.uhook_edit_asset_sidebar(Asset.new).is_a?(String)
  end
  
  test 'uhook_new_asset_sidebar should return string' do
    mock_helper
    Base.current_connector::UbiquoAssetsController::Helper.module_eval do
      module_function :uhook_new_asset_sidebar
    end
    assert Base.current_connector::UbiquoAssetsController::Helper.uhook_new_asset_sidebar(Asset.new).is_a?(String)
  end
  
  test 'uhook_asset_index_actions should return array' do
    mock_helper
    Base.current_connector::UbiquoAssetsController::Helper.module_eval do
      module_function :uhook_asset_index_actions
    end
    assert Base.current_connector::UbiquoAssetsController::Helper.uhook_asset_index_actions(Asset.new).is_a?(Array)
  end
  
  test 'uhook_asset_form should return string' do
    mock_helper
    f = stub_everything
    f.stub_default_value = ''
    Base.current_connector::UbiquoAssetsController::Helper.module_eval do
      module_function :uhook_asset_form
    end
    assert Base.current_connector::UbiquoAssetsController::Helper.uhook_asset_form(f).is_a?(String)
  end

  # Define module mocks for testing
  module Base::Asset; end
  module Base::UbiquoAssetsController; end
#  module Base::AssetRelation; end
  module Base::Migration; end
    
end
