require File.dirname(__FILE__) + "/../../test_helper.rb"

class Ubiquo::AssetsControllerTest < ActionController::TestCase
  use_ubiquo_fixtures
  def test_should_get_index
    get :index
    assert_response :success
    assert_not_nil assigns(:assets)
  end

  def test_should_get_index_with_permission
    login_with_permission(:media_management)
    get :index
    assert_response :success
    assert_not_nil assigns(:assets)
  end

  def test_should_not_get_index_without_permission
    login_with_permission
    get :index
    assert_response :forbidden
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_asset
    assert_difference('Asset.count') do
      post :create, :asset => { :name => "new asset", 
                                :resource => test_file, 
                                :asset_type_id => AssetType.find(:first).id}, 
                                :is_protected => false
    end
    assert_redirected_to ubiquo_assets_path
  end

  def test_should_get_edit
    get :edit, :id => assets(:video).id
    assert_response :success
  end

  def test_should_update_asset
    put :update, :id => assets(:video).id, 
        :asset => { :name => "new asset", 
                    :resource => test_file,
                    :is_protected => false }
    assert_redirected_to ubiquo_assets_path
  end

  def test_should_destroy_asset
    assert_difference('Asset.count', -1) do
      delete :destroy, :id => assets(:video).id
    end

    assert_redirected_to ubiquo_assets_path
  end

  def test_should_filter_by_text_ubiquo_user_and_asset_type
    get :search, :field => 'image', :text => 'MyName', :asset_type_id => 1
    assert_response :success
    assert assigns(:field), 'image'  
    assert assigns(:search_text), 'MyName'
    assert assigns(:page), 1
    assert assigns(:assets).size, 1
    assert assigns(:assets_pages) == {:previous => nil, :next => nil}
  end

  def test_should_filter_by_text_and_ubiquo_user_paginated
    Asset.destroy_all
    list_size = Ubiquo::Config.context(:ubiquo_media).get(:media_selector_list_size)
    ((list_size * 3) - 1).times do
      create_asset(
                   :asset_type_id => asset_types(:asset_types_004).id,
                   :name => "MyName"
                   )
    end
    get :search, :field => 'image', :text => 'MyName', :page => 1
    assert_response :success
    assert_equal assigns(:assets).size, 3
    assert_equal assigns(:assets_pages), {:previous => nil, :next => 2}
    get :search, :field => 'image', :text => 'MyName', :page => 2
    assert_response :success
    assert_equal assigns(:assets).size, 3
    assert_equal assigns(:assets_pages), {:previous => 1, :next => 3}
    get :search, :field => 'image', :text => 'MyName', :page => 3
    # 2 assets fixtures + 6 create = 8. Page 3 should have 2 assets
    assert_response :success
    assert_equal assigns(:assets).size, 2
    assert_equal assigns(:assets_pages), {:previous => 2, :next => nil}    
  end

  def test_should_filter_by_text_and_ubiquo_user_paginated_view
    (Ubiquo::Config.context(:ubiquo_media).get(:assets_elements_per_page) * 2).times do
      create_asset(
                   :asset_type_id => asset_types(:asset_types_004).id, 
                   :name => "MyName" 
                   ) 
    end
    get :search, :field => 'image', :text => 'MyName', :page => 2, :counter => 1
    assert_response :success
    assert_select_rjs "asset_search_results_1" do
      assert_select "ul" do 
        assert_select "li", 3
      end
    end
  end

  def test_filter_by_text_searching_case_insensitive_on_name_and_description
    Asset.delete_all
    asset1 = create_asset(:name => 'name1', :description => 'description1')
    asset2 = create_asset(:name => 'name2', :description => 'description2')
    get :index, :filter_text => 'name'
    assert_equal_set [asset1, asset2], assigns(:assets)
    get :index, :filter_text => 'NAME1'
    assert_equal_set [asset1], assigns(:assets)
    get :index, :filter_text => 'description2'
    assert_equal_set [asset2], assigns(:assets)
  end

  def test_filter_by_creation_date
    Asset.delete_all
    asset1 = create_asset(:created_at => 3.days.ago)
    asset2 = create_asset(:created_at => 1.days.from_now)
    asset3 = create_asset(:created_at => 10.days.from_now)

    I18n.locale = Ubiquo.default_locale
    
    get :index, :filter_created_start => I18n.localize(Date.today)
    assert_equal_set [asset2, asset3], assigns(:assets)
    get :index, :filter_created_end => I18n.localize(Date.today)
    assert_equal_set [asset1], assigns(:assets)
    get :index, :filter_created_start =>  I18n.localize(5.days.ago.to_date), :filter_created_end => I18n.localize(1.days.from_now.to_date)
    assert_equal_set [asset1, asset2], assigns(:assets)
  end
  
  private

  def create_asset(options = {})
    default_options = {
      :name => "Created asset", 
      :description => "Description", 
      :asset_type_id => AssetType.find(:first).id,
      :resource => test_file,
      :is_protected => false,
    }
    
    AssetPublic.create(default_options.merge(options))
  end
  
end
