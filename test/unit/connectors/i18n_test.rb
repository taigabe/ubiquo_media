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
  
  test 'uhook_index_search_subject should return locale filtered assets' do
    Ubiquo::AssetsController.any_instance.expects(:current_locale).at_least_once.returns('ca')
    Asset.expects(:locale).with('ca', :ALL).returns(Asset)
    assert_nothing_raised do
      Ubiquo::AssetsController.new.uhook_index_search_subject.filtered_search
    end
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
  
  test 'uhook_create_asset with from parameter should reassign resource' do
    from_asset = AssetPublic.create(:resource => 'resource', :name => 'asset')
    mock_params :from => from_asset.id
    Ubiquo::AssetsController.any_instance.expects(:current_locale).at_least_once.returns('ca')
    %w{AssetPublic AssetPrivate}.each do |visibility|
      asset = Ubiquo::AssetsController.new.uhook_create_asset visibility.constantize
      assert_equal from_asset.resource_file_name, asset.resource_file_name
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

  test 'uhook_edit_asset_sidebar_should_return_show_translations_links' do
    mock_helper
    I18n::UbiquoAssetsController::Helper.expects(:show_translations).at_least_once.returns('links')
    I18n::UbiquoAssetsController::Helper.module_eval do
      module_function :uhook_edit_asset_sidebar
    end
    assert_equal 'links', I18n::UbiquoAssetsController::Helper.uhook_edit_asset_sidebar(Asset.new)
  end

  test 'uhook_new_asset_sidebar should return show translations links' do
    mock_helper
    I18n::UbiquoAssetsController::Helper.expects(:show_translations).at_least_once.returns('links')
    I18n::UbiquoAssetsController::Helper.module_eval do
      module_function :uhook_new_asset_sidebar
    end
    assert_equal 'links', I18n::UbiquoAssetsController::Helper.uhook_new_asset_sidebar(Asset.new)
  end

  test 'uhook_asset_index_actions should return translate and remove link if not current locale' do
    mock_helper
    asset = Asset.new(:locale => 'ca')
    I18n::UbiquoAssetsController::Helper.expects(:current_locale).returns('en')
    I18n::UbiquoAssetsController::Helper.expects(:ubiquo_asset_path).with(asset, :destroy_content => true)
    I18n::UbiquoAssetsController::Helper.expects(:new_ubiquo_asset_path).with(:from => asset.content_id)
    I18n::UbiquoAssetsController::Helper.module_eval do
      module_function :uhook_asset_index_actions
    end
    actions = I18n::UbiquoAssetsController::Helper.uhook_asset_index_actions asset
    assert actions.is_a?(Array)
    assert_equal 2, actions.size
  end
  
  test 'uhook_asset_index_actions should return removes and edit links if current locale' do
    mock_helper
    asset = Asset.new(:locale => 'ca')
    I18n::UbiquoAssetsController::Helper.stubs(:current_locale).returns('ca')
    I18n::UbiquoAssetsController::Helper.expects(:ubiquo_asset_path).with(asset, :destroy_content => true)
    I18n::UbiquoAssetsController::Helper.expects(:ubiquo_asset_path).with(asset)
    I18n::UbiquoAssetsController::Helper.expects(:edit_ubiquo_asset_path).with(asset)
    
    I18n::UbiquoAssetsController::Helper.module_eval do
      module_function :uhook_asset_index_actions
    end
    actions = I18n::UbiquoAssetsController::Helper.uhook_asset_index_actions asset
    assert actions.is_a?(Array)
    assert_equal 3, actions.size
  end
  
  test 'uhook_asset_form should return content_id field' do
    mock_helper
    f = stub_everything
    f.expects(:hidden_field).with(:content_id).returns('')
    I18n::UbiquoAssetsController::Helper.expects(:params).returns({:from => 100})
    I18n::UbiquoAssetsController::Helper.expects(:hidden_field_tag).with(:from, 100).returns('')
    I18n::UbiquoAssetsController::Helper.module_eval do
      module_function :uhook_asset_form
    end
    I18n::UbiquoAssetsController::Helper.uhook_asset_form(f)
  end
    
end

add_mock_helper_stubs({
  :show_translations => '', :edit_ubiquo_asset_path => '', 
  :new_ubiquo_asset_path => '', :ubiquo_asset_path => '', :current_locale => '',
  :hidden_field_tag => '', :locale => Asset
})
