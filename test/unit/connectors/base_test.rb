require File.dirname(__FILE__) + "/../../test_helper"

class UbiquoMedia::Connectors::BaseTest < ActiveSupport::TestCase

  Base = UbiquoMedia::Connectors::Base
  
  test 'should_load_correct_modules' do
    ::Asset.expects(:include).with(Base::Asset)
    ::Ubiquo::AssetsController.expects(:include).with(Base::UbiquoAssetsController)
#    ::AssetRelation.expects(:include).with(Base::AssetRelation)
    ::ActiveRecord::Migration.expects(:include).with(Base::Migration)
    Base.load!
  end
  
  test 'should_set_current_connector_on_load' do
    save_current_connector
    Base.load!
    assert_equal Base, Base.current_connector
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
  
  test 'uhook_index_filters_should_return_hash' do
    assert Ubiquo::AssetsController.new.uhook_index_filters({}).is_a?(Hash)
  end
  
  test 'uhook_new_asset_should_return_new_asset' do
    asset = Ubiquo::AssetsController.new.uhook_new_asset 
    assert asset.is_a?(Asset)
    assert asset.new_record?
  end
  
  # Define module mocks for testing
  module Base::Asset; end
  module Base::UbiquoAssetsController; end
#  module Base::AssetRelation; end
  module Base::Migration; end
    
end
