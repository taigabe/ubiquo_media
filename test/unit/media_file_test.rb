require File.dirname(__FILE__) + "/../test_helper.rb"

class MediaFileTest < ActiveSupport::TestCase
  use_ubiquo_fixtures

  def test_simple
    t = AssetType.find(:first)
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
    t = AssetType.find(:first)
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
    t = AssetType.find(:first)
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
    t = AssetType.find(:first)
    a = assets(:video)
    assert t.all_types.accepts?(a)
    a = assets(:audio)
    assert t.all_types.accepts?(a)
  end
  def test_some_types
    t = AssetType.first
    a = assets(:video)
    assert t.some_types.accepts?(a)
    a = assets(:doc)
    assert !t.some_types.accepts?(a)
  end

  def test_insertion_of_asset_relations
    AssetRelation.destroy_all

    t = AssetType.find(:first)
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
      t = AssetType.new :simple_ids => [a.id.to_s]
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
      t = AssetType.create :multiple_ids => ["", {"id" => a.id.to_s, "name" => "Test name"}, {"id" => b.id.to_s, "name" => "Test name 2"}]
    end
    t.multiple.reload
    assert_equal t.name_for_asset(:multiple, t.multiple[0]), "Test name"
    assert_equal t.name_for_asset(:multiple, t.multiple[1]), "Test name 2"
  end

  def test_empty_ids
    a = Asset.find(:first)
    t = nil
    assert_difference "::AssetRelation.count" do
      t = AssetType.create :simple_ids => ["", a.id.to_s]
    end
    simples = t.simple
    assert_equal t.simple.size, 1
  end


  def test_relation_order_on_creation
    AssetRelation.delete_all
    a = Asset.find(:first)
    b = Asset.find(:first, :offset => 1)
    assert_difference "::AssetRelation.count", 2 do
      AssetType.create :multiple_ids => ["", {"id" => a.id.to_s, "name" => "Test name"}, {"id" => b.id.to_s, "name" => "Test name 2"}]
    end
    assert_equal AssetRelation.find(:first).position, 1
    assert_equal AssetRelation.find(:first, :offset => 1).position, 2
  end

  def test_relation_order_on_update
    AssetRelation.delete_all
    asset_one, asset_two = Asset.find(:first), Asset.find(:first, :offset => 1)
    asset_relations = [ 
      { "id" => asset_one.id.to_s, "name" => "Relation to asset one" },
      { "id" => asset_two.id.to_s, "name" => "Relation to asset two" } 
    ]
    asset_type = AssetType.create :multiple_ids => asset_relations
    asset_type.multiple_ids = asset_relations.reverse
    asset_type.save

    assert_equal AssetRelation.find(:first, :order => "id").position, 2
    assert_equal AssetRelation.find(:first, :order => "id", :offset => 1).position, 1
  end

  
  def test_name_for_asset_should_work_when_multiple_media_attachments_are_in_use
    a = assets(:audio)
    t = AssetType.create :simple_ids => [a.id.to_s]
    t.name_for_asset(:simple,a)
    t.update_attributes :some_types_ids => [{"id" => a.id.to_s, "name" => "Test name"}]
    t = AssetType.find(t.id)
    assert_equal [a], t.some_types
  end
  
  def test_should_destroy_old_relations
    AssetRelation.destroy_all
    a = Asset.find(:first)
    b = Asset.find(:first, :offset => 1)
    t = nil
    assert_difference "AssetRelation.count" do
      t = AssetType.create :simple_ids => [{ "id" => a.id.to_s}]
    end
    assert_no_difference "AssetRelation.count" do
      t.simple_ids = [{"id" => b.id.to_s}]
      t.save
    end
  end
end
