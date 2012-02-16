require File.dirname(__FILE__) + "/../test_helper.rb"

class AssetTypeTest < ActiveSupport::TestCase
  use_ubiquo_fixtures

  def test_get_by_keys
    assert_equal AssetType.all, AssetType.get_by_keys(:ALL)
    assert_equal [AssetType.find_by_key("image"),AssetType.find_by_key("doc")],
      AssetType.get_by_keys([:image,:doc])
  end

  def test_key_should_be_unique
    key = 'my_key'
    asset_type = AssetType.new(:key => key)
    assert asset_type.save

    new_asset_type = AssetType.new(:key => key)
    assert !new_asset_type.valid?
    assert new_asset_type.errors.on(:key)
  end
end
