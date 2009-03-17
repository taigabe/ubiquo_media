require File.dirname(__FILE__) + "/../test_helper.rb"

class AssetTagTest < ActiveSupport::TestCase
  use_ubiquo_fixtures
  
  def test_should_create_asset_tag
    assert_difference "AssetTag.count" do
      at = create_asset_tag
      assert !at.new_record?, "#{at.errors.full_messages.to_sentence}"
    end
  end
  
  private
  def create_asset_tag(options = {})
    AssetTag.create({:asset_id => Asset.find(:first).id, :tag_id => Tag.find(:first).id}.merge!(options))
  end
end
