require File.dirname(__FILE__) + "/../test_helper.rb"

class AssetTest < ActiveSupport::TestCase
  use_ubiquo_fixtures
  def test_should_create_asset
    assert_difference "Asset.count" do
      asset = create_asset
      assert !asset.new_record?, "#{asset.errors.full_messages.to_sentence}"
    end
  end

  def test_should_require_name
    assert_no_difference "Asset.count" do
      asset = create_asset :name => nil
      assert asset.errors.on(:name)
    end
  end

  def test_should_require_resource
    assert_no_difference "Asset.count" do
      asset = create_asset :resource => nil
      assert asset.errors.on(:resource)
    end
  end

  def test_should_require_asset_type_id
    assert_no_difference "Asset.count" do
      #if asset hasn't resource, it can't set asset type
      asset = create_asset :resource => nil
      assert asset.errors.on(:asset_type_id)
    end
  end

  def test_simple_filter
    assets = Asset.filtered_search
    assert_equal assets.size, Asset.count
  end

  def test_filter_by_text_searching_case_insensitive_on_name_and_description
    Asset.delete_all
    asset1 = create_asset(:name => 'name1', :description => 'description1')
    asset2 = create_asset(:name => 'name2', :description => 'description2')
    assert_equal_set [asset1, asset2], Asset.filtered_search({:text => 'name'})
    assert_equal_set [asset1], Asset.filtered_search({:text => 'nAMe1'})
    assert_equal_set [asset2], Asset.filtered_search({:text => 'DESCRIPTION2'})    
  end

  def test_filter_by_creation_date
    Asset.delete_all
    asset1 = create_asset(:created_at => 3.days.ago)
    asset2 = create_asset(:created_at => 1.days.from_now)
    asset3 = create_asset(:created_at => 10.days.from_now)
    assert_equal_set [asset2, asset3], Asset.filtered_search({:created_start => Time.now}, {})
    assert_equal_set [asset1], Asset.filtered_search({:created_end => Time.now}, {})
    assert_equal_set [asset1, asset2], Asset.filtered_search({:created_start => 5.days.ago, :created_end => 1.days.from_now}, {})
  end
  
  def test_should_be_stored_in_public_path
     asset = create_asset(:name => "FAKE")
    assert asset.resource.path =~ /#{File.join(RAILS_ROOT, Ubiquo::Config.get(:attachments)[:public_path])}/
  end
  
  def test_should_be_stored_in_protected_path
    asset = AssetPrivate.create(:name => "FAKE2",
                                :resource => test_file,
                                :asset_type_id => AssetType.find(:first).id)
    assert asset.resource.path =~ /#{File.join(RAILS_ROOT, Ubiquo::Config.get(:attachments)[:private_path])}/    
  end

  private
    
  def create_asset(options = {})
    default_options = {
      :name => "Created asset", 
      :description => "Description", 
      :resource => test_file,       
    }
    a = AssetPublic.create(default_options.merge(options))
  end
  
end
