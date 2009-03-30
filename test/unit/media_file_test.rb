require File.dirname(__FILE__) + "/../test_helper.rb"

class MediaFileTest < ActiveSupport::TestCase
  use_ubiquo_fixtures

  def test_simple
    t = AssetTag.find(:first)
    a = Asset.find(:first)

    assert !t.simple.is_full?
    assert_difference "::AssetRelation.count" do
      assert_difference "t.simple.size" do
        t.simple << a
      end
    end

    assert t.simple.is_full?
  end

  def test_multiple
    t = AssetTag.find(:first)
    a = Asset.find(:first)
    b = Asset.find(:first, :offset => 1)
    assert a!=b

    assert !t.multiple.is_full?
    assert_difference "::AssetRelation.count" do
      assert_difference "t.multiple.size" do
        t.multiple << a
      end
    end
    assert !t.multiple.is_full?
  end

  def test_sized

    t = AssetTag.find(:first)
    a = Asset.find(:first)
    b = Asset.find(:first, :offset => 1)
    assert a!=b

    assert !t.sized.is_full?
    assert_difference "::AssetRelation.count",2 do
      assert_difference "t.sized.size",2 do
        t.sized << [a,b]
      end
    end
    assert t.sized.is_full?
  end

  def test_all_types
    t = AssetTag.find(:first)
    a = assets(:video)
    assert t.all_types.accepts?(a)
    a = assets(:audio)
    assert t.all_types.accepts?(a)
  end
  def test_some_types
    t = AssetTag.first
    a = assets(:video)
    assert t.some_types.accepts?(a)
    a = assets(:doc)
    assert !t.some_types.accepts?(a)
  end

  def test_insertion_of_asset_relations
    AssetRelation.destroy_all

    t = AssetTag.find(:first)
    a = Asset.find(:first)
    assert_difference "::AssetRelation.count" do
      assert_difference "t.simple.size" do
        t.simple << a
      end
    end

    rel = AssetRelation.find(:first)
    assert rel.field_name == 'simple'
  end

  def test_insertion_on_save_and_create
    a = Asset.find(:first)
    t=nil
    assert_no_difference "::AssetRelation.count" do
      t = AssetTag.new :simple_ids => [a.id.to_s]
    end

    assert_difference "t.simple.size" do
      assert_difference "::AssetRelation.count" do
        assert t.save
      end
    end
  end
  def test_named_relations
    a = Asset.find(:first)
    b = Asset.find(:first, :offset => 1)
    t = nil
    assert_difference "::AssetRelation.count", 2 do
      t = AssetTag.create :multiple_ids => ["", {"id" => a.id.to_s, "name" => "Test name"}, {"id" => b.id.to_s, "name" => "Test name 2"}]
    end
    t.multiple.reload
    assert_equal t.name_for_asset(:multiple, t.multiple[0]), "Test name"
    assert_equal t.name_for_asset(:multiple, t.multiple[1]), "Test name 2"
  end

  def test_empty_ids
    a = Asset.find(:first)
    t = nil
    assert_difference "::AssetRelation.count" do
      t = AssetTag.create :simple_ids => ["", a.id.to_s]
    end
    simples = t.simple
    assert_equal t.simple.size, 1
  end


  def test_order
    AssetRelation.delete_all
    a = Asset.find(:first)
    b = Asset.find(:first, :offset => 1)
    assert_difference "::AssetRelation.count", 2 do
      AssetTag.create :multiple_ids => ["", {"id" => a.id.to_s, "name" => "Test name"}, {"id" => b.id.to_s, "name" => "Test name 2"}]
    end
    assert_equal AssetRelation.find(:first).position, 1
    assert_equal AssetRelation.find(:first, :offset => 1).position, 2
  end
  
  def test_name_for_asset_should_work_when_multiple_media_attachments_are_in_use
    a = assets(:audio)
    t = AssetTag.create :simple_ids => [a.id.to_s]
    t.name_for_asset(:simple,a)
    t.update_attributes :some_types_ids => [{"id" => a.id.to_s, "name" => "Test name"}]
    t = AssetTag.find(t.id)
    assert_equal [a], t.some_types
  end
end

class AssetTag # Using this model because is very simple and has no validations
  media_attachment :simple
  media_attachment :multiple, :size => :many
  media_attachment :sized, :size => 2
  media_attachment :all_types, :types => :ALL
  media_attachment :some_types, :types => %w{audio video}
end
