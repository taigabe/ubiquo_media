require File.dirname(__FILE__) + "/../../test_helper"

class UbiquoMedia::Connectors::StandardTest < ActiveSupport::TestCase
  
  Standard = UbiquoMedia::Connectors::Standard

  def setup
    save_current_connector
    Standard.load!
  end
  
  def teardown
    reload_old_connector
  end
  
  
  test 'uhook_create_assets_table_should_create_table' do
    ActiveRecord::Migration.expects(:create_table).with(:assets)
    ActiveRecord::Migration.uhook_create_assets_table {}
  end
  
  test 'uhook_filtered_search_in_asset_should_yield' do
    Asset.expects(:all)
    Asset.uhook_filtered_search { Asset.all }
  end
  
  test 'uhook_index_filters_should_return_empty_hash' do
    assert_equal({}, Ubiquo::AssetsController.new.uhook_index_filters)
  end
  
  test 'uhook_new_asset_should_return_new_asset' do
    asset = Ubiquo::AssetsController.new.uhook_new_asset 
    assert asset.is_a?(AssetPublic)
    assert asset.new_record?
  end
  
  test 'uhook_create_asset_should_return_new_asset' do
    mock_params
    %w{AssetPublic AssetPrivate}.each do |visibility|
      asset = Ubiquo::AssetsController.new.uhook_create_asset visibility.constantize
      assert_equal visibility, asset.class.to_s
      assert asset.new_record?
    end
  end
  
  test 'uhook_destroy_asset_should_destroy_asset' do
    Asset.any_instance.expects(:destroy).returns(:value)
    assert_equal :value, Ubiquo::AssetsController.new.uhook_destroy_asset(Asset.new)
  end

  test 'uhook_asset_filters_should_return_empty_string' do
    Standard::UbiquoAssetsController::Helper.module_eval do
      module_function :uhook_asset_filters
    end
    assert_equal '', Standard::UbiquoAssetsController::Helper.uhook_asset_filters('')
  end
  
  test 'uhook_asset_filters_info_should_return_empty_array' do
    Standard::UbiquoAssetsController::Helper.module_eval do
      module_function :uhook_asset_filters_info
    end
    assert_equal [], Standard::UbiquoAssetsController::Helper.uhook_asset_filters_info
  end

  test 'uhook_edit_asset_sidebar_should_return_empty_string' do
    mock_helper
    Standard::UbiquoAssetsController::Helper.module_eval do
      module_function :uhook_edit_asset_sidebar
    end
    assert_equal '', Standard::UbiquoAssetsController::Helper.uhook_edit_asset_sidebar
  end
end
