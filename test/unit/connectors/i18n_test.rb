require File.dirname(__FILE__) + "/../../test_helper"

class UbiquoMedia::Connectors::I18nTest < ActiveSupport::TestCase
  
  I18n = UbiquoMedia::Connectors::I18n

  def setup
    save_current_connector
    I18n.load!
  end
  
  def teardown
    reload_old_connector
  end
  
  
  test 'uhook_create_assets_table_should_create_table_with_i18n_info' do
    ActiveRecord::Migration.expects(:create_table).with(:assets, :translatable => true)
    ActiveRecord::Migration.uhook_create_assets_table {}
  end
  
  test 'uhook_filtered_search_in_asset_should_yield_with_locale_filter' do
    Asset.expects(:all)
    Asset.expects(:with_scope).with(:find => {:conditions => ["assets.locale <= ?", 'ca']}).yields
    Asset.uhook_filtered_search({:locale => 'ca'}) { Asset.all }
  end
  
  test 'uhook_index_filters_should_return_locale_filter' do
    mock_params :filter_locale => 'ca'
    assert_equal({:locale => 'ca'}, Ubiquo::AssetsController.new.uhook_index_filters)
  end
  
  test 'uhook_new_asset_should_return_translated_asset' do
    mock_params :from => 1
    Ubiquo::AssetsController.any_instance.expects(:current_locale).returns('ca')
    AssetPublic.expects(:translate).with(1, 'ca', :copy_all => true)
    asset = Ubiquo::AssetsController.new.uhook_new_asset 
  end
  
  test 'uhook_create_asset_should_return_new_asset_with_current_locale' do
    mock_params
    Ubiquo::AssetsController.any_instance.expects(:current_locale).at_least_once.returns('ca')
    %w{AssetPublic AssetPrivate}.each do |visibility|
      asset = Ubiquo::AssetsController.new.uhook_create_asset visibility.constantize
      assert_equal visibility, asset.class.to_s
      assert_equal 'ca', asset.locale
      assert asset.new_record?
    end
  end
  
  test 'uhook_destroy_asset_should_destroy_asset' do
    Asset.any_instance.expects(:destroy).returns(:value)
    mock_params :destroy_content => false
    assert_equal :value, Ubiquo::AssetsController.new.uhook_destroy_asset(Asset.new)
  end

  test 'uhook_destroy_asset_should_destroy_asset_content' do
    Asset.any_instance.expects(:destroy_content).returns(:value)
    mock_params :destroy_content => true
    assert_equal :value, Ubiquo::AssetsController.new.uhook_destroy_asset(Asset.new)
  end

  test 'uhook_asset_filters_should_return_locale_filter' do
    mock_helper
    UbiquoMedia::Connectors::Base.current_connector::UbiquoAssetsController::Helper.expects(:render_filter).at_least_once.with(
      :links, '',
      :caption => ::Asset.human_attribute_name("locale"),
      :field => :filter_locale,
      :collection => Locale.active,
      :id_field => :iso_code,
      :name_field => :native_name
    ).returns('filter')
    
    I18n::UbiquoAssetsController::Helper.module_eval do
      module_function :uhook_asset_filters
    end
    
    assert !I18n::UbiquoAssetsController::Helper.uhook_asset_filters('').blank?
  end
  
  test 'uhook_asset_filters_info_should_return_locale_filter_info' do
    mock_helper
    UbiquoMedia::Connectors::Base.current_connector::UbiquoAssetsController::Helper.expects(:filter_info).at_least_once.with(
      :string, {},
      :field => :filter_locale,
      :caption => ::Asset.human_attribute_name("locale")      
    )
    I18n::UbiquoAssetsController::Helper.module_eval do
      module_function :uhook_asset_filters_info
    end
    assert_equal 1, I18n::UbiquoAssetsController::Helper.uhook_asset_filters_info.size
  end

end
