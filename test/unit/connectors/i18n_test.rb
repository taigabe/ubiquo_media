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
  
  test 'Asset should be translatable' do
    [Asset, AssetPublic, AssetPrivate].each do |klass|
      assert klass.is_translatable?
    end
  end

  test 'AssetRelation should be translatable' do
    assert AssetRelation.is_translatable?
  end

  test 'uhook_create_assets_table_should_create_table_with_i18n_info' do
    ActiveRecord::Migration.expects(:create_table).with(:assets, :translatable => true)
    ActiveRecord::Migration.uhook_create_assets_table {}
  end
  
  test 'uhook_create_asset_relations_table_should_create_table' do
    ActiveRecord::Migration.expects(:create_table).with(:asset_relations, :translatable => true)
    ActiveRecord::Migration.uhook_create_asset_relations_table {}
  end

  test 'uhook_filtered_search_in_asset_should_yield_with_locale_filter' do
    Asset.expects(:all)
    Asset.expects(:with_scope).with(:find => {:conditions => ["assets.locale <= ?", 'ca']}).yields
    Asset.uhook_filtered_search({:locale => 'ca'}) { Asset.all }
  end
  
  test 'uhook_after_update in asset should update resource in translations' do
    asset_1 = AssetPublic.new(:locale => 'ca', :resource => 'one')
    asset_2 = AssetPublic.new(:locale => 'en')
    asset_1.expects(:translations).returns([asset_2])
    asset_2.expects(:resource=)
    asset_2.expects(:save)
    asset_1.uhook_after_update
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
  
  test 'uhook_edit_asset should not return false if current locale' do
    Ubiquo::AssetsController.any_instance.expects(:current_locale).at_least_once.returns('ca')
    assert_not_equal false, Ubiquo::AssetsController.new.uhook_edit_asset(Asset.new(:locale => 'ca'))
  end
  
  test 'uhook_edit_asset should redirect if not current locale' do
    Ubiquo::AssetsController.any_instance.expects(:current_locale).at_least_once.returns('ca')
    Ubiquo::AssetsController.any_instance.expects(:ubiquo_assets_path).at_least_once.returns('')
    Ubiquo::AssetsController.any_instance.expects(:redirect_to).at_least_once
    Ubiquo::AssetsController.new.uhook_edit_asset Asset.new(:locale => 'en')
    assert_equal false, Ubiquo::AssetsController.new.uhook_edit_asset(Asset.new(:locale => 'en'))
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
    
  test 'uhook_media_attachment should add translation_shared option if set' do
    AssetType.uhook_media_attachment :simple, {:translation_shared => true}
    assert AssetType.reflections[:simple].options[:translation_shared]
  end
  
  test 'uhook_media_attachment should not add translation_shared option if not set' do
    AssetType.uhook_media_attachment :simple, {:translation_shared => false}
    assert !AssetType.reflections[:simple].options[:translation_shared]
  end

  test 'uhook_asset_relation_scoped_creation should set asset locale in create scope' do
    asset = AssetPublic.create(:locale => 'ca')
    AssetRelation.uhook_asset_relation_scoped_creation(asset) do
      asset = AssetRelation.create
      assert_equal 'ca', asset.locale
    end
  end

  test 'uhook_asset_relation_scoped_creation should only set relation locale for the current relation' do
    original_options = AssetPublic.reflections[:asset_relations].options
    AssetPublic.reflections[:asset_relations].instance_variable_set('@options', original_options.merge(:translation_shared => true))

    asset = AssetPublic.create :locale => 'ca', :resource => Tempfile.new('tmp'), :name => 'asset'
    translated_asset = asset.translate('en', :copy_all => true)
    translated_asset.save
    AssetRelation.uhook_asset_relation_scoped_creation(asset) do
      asset.asset_relations << AssetRelation.create(:related_object => asset)
      assert_equal 'ca', asset.asset_relations.first.locale
      assert_equal 1, translated_asset.reload.asset_relations.size
      assert_equal 'en', translated_asset.asset_relations.first.locale
    end

    AssetPublic.reflections[:asset_relations].instance_variable_set('@options', original_options)
  end

  test 'should not share attachments between translations' do
    AssetPublic.class_eval do
      media_attachment :photo
    end

    asset = AssetPublic.create :locale => 'ca', :resource => Tempfile.new('tmp'), :name => 'asset'
    translated_asset = asset.translate('en', :copy_all => true)
    translated_asset.save
    
    asset.photo << AssetPublic.create(:locale => 'ca', :resource => Tempfile.new('tmp'), :name => 'photo')
    assert_equal 0, translated_asset.reload.photo.size
  end

  test 'should share attachments between translations' do
    AssetPublic.class_eval do
      media_attachment :photo, :translation_shared => true
    end

    asset = AssetPublic.create :locale => 'ca', :resource => Tempfile.new('tmp'), :name => 'asset'
    translated_asset = asset.translate('en', :copy_all => true)
    translated_asset.save

    asset.photo << AssetPublic.create(:locale => 'ca', :resource => Tempfile.new('tmp'), :name => 'photo')
    assert_equal 1, translated_asset.reload.photo.size
    assert_equal 'en', translated_asset.photo.first.locale
  end

  test 'should only update asset relation name in one translation' do
    AssetPublic.class_eval do
      media_attachment :photo, :translation_shared => true
    end

    asset = AssetPublic.create :locale => 'ca', :resource => Tempfile.new('tmp'), :name => 'asset'
    translated_asset = asset.translate('en', :copy_all => true)
    translated_asset.save
    asset.photo << original_photo = AssetPublic.create(:locale => 'ca', :resource => Tempfile.new('tmp'), :name => 'photo')

    # save the original name in the translation and then update it
    original_name = AssetRelation.name_for_asset :photo, translated_asset.photo.first, translated_asset
    asset.photo_ids = [{"id" => original_photo.id, "name" => 'newname'}]
    asset.save

    # name successfully changed
    assert_equal 'newname', AssetRelation.first(:conditions => {:related_object_id => asset.id}).name
    # translation untouched
    assert_equal original_name, AssetRelation.first(:conditions => {:related_object_id => translated_asset.id}).name
  end
end

add_mock_helper_stubs({
  :show_translations => '', :edit_ubiquo_asset_path => '', 
  :new_ubiquo_asset_path => '', :ubiquo_asset_path => '', :current_locale => '',
  :hidden_field_tag => '', :locale => Asset
})
