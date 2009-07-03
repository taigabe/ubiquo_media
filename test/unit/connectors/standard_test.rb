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
    assert_equal({}, Ubiquo::AssetsController.new.uhook_index_filters({}))
  end
  
  test 'uhook_new_asset_should_return_new_asset' do
    asset = Ubiquo::AssetsController.new.uhook_new_asset 
    assert asset.is_a?(Asset)
    assert asset.new_record?
  end
  
end
