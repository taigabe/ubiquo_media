require File.dirname(__FILE__) + "/../test_helper.rb"

class AssetTypeTest < ActiveSupport::TestCase
  use_ubiquo_fixtures
  
  def test_get_by_keys
    assert_equal AssetType.all, AssetType.get_by_keys(:ALL)
    assert_equal [AssetType.find_by_key("image"),AssetType.find_by_key("doc")], 
      AssetType.get_by_keys([:image,:doc])
  end
end
