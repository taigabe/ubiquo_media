require File.dirname(__FILE__) + "/../test_helper.rb"

class AssetRelationTest < ActiveSupport::TestCase
  use_ubiquo_fixtures
  
  def test_should_delete_all_relations
    all_asset_ids = Asset.all.collect(&:id).collect(&:to_s)
    obj = UbiquoMedia::TestModel.create(:images_ids => all_asset_ids,
                                        :field => "value")
    assert_difference 'AssetRelation.count', -Asset.count do
      obj.update_attributes(:images_ids => [])
    end
    assert_equal [], obj.reload.images
  end
end

ActiveRecord::Base.connection.create_table(:ubiquo_media_test_models, :force => true) do |t|
  t.string :field
end

class UbiquoMedia::TestModel < ActiveRecord::Base
  set_table_name 'ubiquo_media_test_models'
  media_attachment :images, :size => :many
end
